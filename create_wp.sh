#!/bin/bash

if [ $# -lt 1 ]; then
    echo usage: create_wp domain [email]
    exit 1
fi

domain=$1

PATH=$PATH:/usr/local/vesta/bin
export PATH

user=$(/usr/local/vesta/bin/v-search-domain-owner $domain)

email="info@$domain";
if [ $# -gt 1 ]; then
    email=$2
fi

if [ ! -d "/home/$user" ]; then
    echo "User doesn't exist";
    exit 1;
fi

if [ ! -d "/home/$user/web/$domain/public_html" ]; then
    echo "Domain doesn't exist";
    exit 1;
fi

WORKINGDIR="/home/$user/web/$domain/public_html"
# FILE=latest.tar.gz

rm -rf $WORKINGDIR/*

#DBUSERSUF=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
DBUSERSUFB="wp";
i=0;
while [ $i -lt 99 ]
do
i=$((i+1));
DBUSERSUF="${DBUSERSUFB}${i}";
DBUSER=$user\_$DBUSERSUF;
if [ ! -d "/var/lib/mysql/$DBUSER" ]; then
break;
fi
done
PASSWDDB=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

v-add-database $user $DBUSERSUF $DBUSERSUF $PASSWDDB mysql

cd /home/$user

rm -rf /home/$user/wp
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar wp

cd /home/$user/web/$domain/public_html

sudo -H -u$user /home/$user/wp core download
sudo -H -u$user /home/$user/wp core config --dbname=$DBUSER --dbuser=$DBUSER --dbpass=$PASSWDDB

password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)

sudo -H -u$user /home/$user/wp core install --url="$domain" --title="$domain" --admin_user="admin" --admin_password="$password" --admin_email="$email" --path=$WORKINGDIR

#FIX za https://github.com/wp-cli/wp-cli/issues/2632

mysql -u$DBUSER -p$PASSWDDB -e "USE $DBUSER; update wp_options set option_value = 'http://$domain' where option_name = 'siteurl'; update wp_options set option_value = 'http://$domain' where option_name = 'home';"

# clear

echo "================================================================="
echo "Installation is complete. Your username/password is listed below."
echo ""
echo "Site: http://$domain/"
echo ""
echo "Login: http://$domain/wp-admin/"
echo "Username: admin"
echo "Password: $password"
echo ""
echo "================================================================="

chown -R $user:$user $WORKINGDIR

rm -rf /home/$user/wp

echo "create_wp: Done."
exit 0

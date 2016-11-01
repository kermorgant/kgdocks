#!/bin/bash

# check if db hostname resolvs
getent hosts ${DB_HOST} > /dev/null
if [ $? -ne 0 ]
then
    echo "ERROR : unable to get ip address for host ${DB_HOST}"
    echo "Did you set the DB_HOST environment variable ?"
    exit 1
fi

# check if connexion to do is ok
#echo "checking if db server is reachable"
/usr/local/bin/wait-for-it.sh -q -t 300 ${DB_HOST}:${DB_PORT}
#timeout 1 bash -c 'cat < /dev/null > /dev/tcp/${DB_HOST}/${DB_PORT}'
if [ $? -ne 0 ]
then
    echo "network connectivity to db is not ok"
    exit 2
fi

# init db, according to env var
if [ $INIT_DB == "true" ]
then
    echo "creating db user"
    mysql -u root -p${DB_ROOT_PASSWORD} -h ${DB_HOST} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"

    echo "creating database"
    mysql -u root -p${DB_ROOT_PASSWORD} -h ${DB_HOST} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"

    echo "granting access"
    mysql -u root -p${DB_ROOT_PASSWORD} -h ${DB_HOST} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"

    mysql -u root -p${DB_ROOT_PASSWORD} -h ${DB_HOST} -e "flush privileges;"
fi

# check credentials
mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e"quit"
if [ $? -ne 0 ]
then
    echo "ERROR: authentication problem. Are DB_USER & DB_PASSWORD set ?"
    exit 3
fi

# check if database exists
mysqlshow -h ${DB_HOST} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_NAME} | grep -v Wildcard | grep -o ${DB_NAME}
if [ $? -ne 0 ]
then
    echo "ERROR: database ${DB_NAME} not found. Is DB_NAME set ?"
    exit 4
fi

# The database should be ready now.

APACHE_DIR="/var/www"
GLPI_DIR="${APACHE_DIR}/glpi"

### INSTALL GLPI IF NOT INSTALLED ALREADY ######################################

if [ -d "$GLPI_DIR" ]; then
    echo "GLPI is already installed at ${GLPI_DIR}"
else
    echo '-----------> Install GLPI'
    mkdir -p $GLPI_DIR
    echo "Using ${GLPI_SOURCE_URL}"
    curl -SL $GLPI_SOURCE_URL | tar -xzC $GLPI_DIR --strip=1
    chown -R www-data $GLPI_DIR
fi

VHOST=/etc/apache2/sites-enabled/000-default.conf

# Use /var/www/html/glpi as DocumentRoot
sed -i -- 's/DocumentRoot .*/DocumentRoot \/var\/www\/glpi/g' $VHOST
# Remove ServerSignature (secutiry)
sed -i -- '/ServerSignature /d' $VHOST
awk '/<\/VirtualHost>/{print "ServerSignature Off" RS $0;next}1' $VHOST > tmp && mv tmp $VHOST
# Eenable .htaccess
sed -i -- '/<Directory /d' $VHOST
awk '/<\/VirtualHost>/{print "<Directory \"/var/www/glpi\">" RS $0;next}1' $VHOST > tmp && mv tmp $VHOST
sed -i -- '/AllowOverride All/d' $VHOST
awk '/<\/VirtualHost>/{print "AllowOverride All" RS $0;next}1' $VHOST > tmp && mv tmp $VHOST
sed -i -- '/<\/Directory/d' $VHOST
awk '/<\/VirtualHost>/{print "</Directory>" RS $0;next}1' $VHOST > tmp && mv tmp $VHOST

chown www-data .

echo "Starting apache"
exec "$@"

#!/bin/bash

if [ -e "/INSTALL-FLAG" ]
then

  sed -i "s/#SERVER_NAME#/ds.${DOMAIN}/" /etc/nginx/conf.d/ds.conf
  sed -i "s/#SERVER_NAME#/booked.${DOMAIN}/" /etc/nginx/conf.d/booked.conf
  sed -i "s/#SERVER_NAME#/support.${DOMAIN}/" /etc/nginx/conf.d/osticket.conf
  sed -i "s/#SERVER_NAME#/redmine.${DOMAIN}/" /etc/nginx/conf.d/redmine.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/redmine.conf    
  sed -i "s/#SERVER_NAME#/archive.redmine.${DOMAIN}/" /etc/nginx/conf.d/redmine-legacy.conf  
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/redmine-legacy.conf  
  sed -i "s/#SERVER_NAME#/erp.${DOMAIN}/" /etc/nginx/conf.d/odoo.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/odoo.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/tunnel.conf  
  sed -i "s/#SERVER_NAME#/jenkins.${DOMAIN}/" /etc/nginx/conf.d/jenkins.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/jenkins.conf
  
  rm -f /INSTALL-FLAG
fi

echo "Waiting for php-fpm for xibo to start - max 10 seconds"
/usr/local/bin/wait-for-it.sh -q -t 10 xibo:9000
    
if [ ! "$?" == 0 ]
then
  echo "php-fpm for xibo didn't start in the allocated time"
else
  echo "php-fpm for xibo started"
fi


echo "Waiting for php-fpm for osticket to start - max 10 seconds"
/usr/local/bin/wait-for-it.sh -q -t 10 osticket:9000
    
if [ ! "$?" == 0 ]
then
  echo "php-fpm for osticket didn't start in the allocated time"
else
  echo "php-fpm for osticket started"
fi


echo "Starting nginx"
exec "$@"

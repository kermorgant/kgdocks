#!/bin/bash

if [ -e "/INSTALL-FLAG" ]
then

  sed -i "s/#SERVER_NAME#/ds.${DOMAIN}/" /etc/nginx/conf.d/ds.conf
  sed -i "s/#SERVER_NAME#/booked.${DOMAIN}/" /etc/nginx/conf.d/booked.conf
  sed -i "s/#SERVER_NAME#/help.${DOMAIN}/" /etc/nginx/conf.d/osticket.conf
  sed -i "s/#SERVER_NAME#/archive.redmine.${DOMAIN}/" /etc/nginx/conf.d/redmine.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/redmine.conf  
  sed -i "s/#SERVER_NAME#/erp.${DOMAIN}/" /etc/nginx/conf.d/odoo.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/odoo.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/tunnel.conf  
  sed -i "s/#SERVER_NAME#/jenkins.${DOMAIN}/" /etc/nginx/conf.d/jenkins.conf
  sed -i "s/#SSL_CA_PATH#/${SSL_CA_PATH}/" /etc/nginx/conf.d/jenkins.conf
  
  rm -f /INSTALL-FLAG
fi

# Sleep for a few seconds to give odoo time to start
echo "Waiting for odoo to start - max 300 seconds"
#/usr/local/bin/wait-for-it.sh -q -t 300 odoo:8069

if [ ! "$?" == 0 ]
then
  echo "odoo didn't start in the allocated time"
else
  echo "odoo started"
fi
# Safety sleep to give odoo a moment to settle after coming up
sleep 1

# Sleep for a few seconds to give redmine time to start
echo "Waiting for redmine to start - max 60 seconds"
#/usr/local/bin/wait-for-it.sh -q -t 60 redmine:300
    
if [ ! "$?" == 0 ]
then
  echo "redmine didn't start in the allocated time"
else
  echo "redmine started"
fi

# Sleep for a few seconds to give php/xibo time to start
echo "Waiting for php-fpm for xibo to start - max 30 seconds"
/usr/local/bin/wait-for-it.sh -q -t 30 xibo:9000
    
if [ ! "$?" == 0 ]
then
  echo "php-fpm for xibo didn't start in the allocated time"
else
  echo "php-fpm for xibo started"
fi

# Sleep for a few seconds to give jenkins time to start
echo "Waiting for jenkins to start - max 30 seconds"
#/usr/local/bin/wait-for-it.sh -q -t 30 jenkins:8080
    
if [ ! "$?" == 0 ]
then
  echo "jenkins didn't start in the allocated time"
else
  echo "jenkins started"
fi


echo "Starting nginx"
exec "$@"

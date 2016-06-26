#!/bin/bash

# Detect if we're going to run an upgrade
if [ -e "/INSTALL-FLAG" ]
then
  if [ -e "/var/www/booked/config/config.php" ]
  then
    # Backup the settings.php file, Web/uploads directory and database
    mv /var/www/booked/config.php /tmp/config.php
    mv /var/www/booked/Web/uploads /var/www/    
    
    mysqldump -h mariadb -u $DB_BOOKED_USER -p$DB_BOOKED_PASSWORD $DB_NAME | gzip > /var/www/$(date +"%Y-%m-%d_%H-%M-%S").sql.gz

    # Delete the old install
    find /var/www/booked/ -exec rm -rf {}\;

    # Restore settings
    mv /tmp/config.php /var/www/booked/config/config.php
    
  fi
  
  curl -SL http://downloads.sourceforge.net/project/phpscheduleit/Booked/2.5/booked-${BOOKED_VERSION}.zip /var/www/booked.zip
  unzip -d "/var/www/booked" "/var/www/booked.zip" && f=(/var/www/booked/*) && mv /var/www/booked/*/* /var/www/booked && rmdir "${f[@]}"
  
  # if we have a backup of uploads, restore it
  if [ -d "/var/www/uploads" ]
  then
    rmdir /var/www/booked/Web/uploads/images &&  rmdir /var/www/booked/Web/uploads/images
    mv /var/www/uploads/ /var/www/booked/Web/  
  fi  

  rm /var/www/booked.zip

  chown www-data.www-data -R /var/www/booked
  
  if [ ! -e "/var/www/booked/config/config.php" ]
  then
    # This is a fresh install so bootstrap the whole
    # system
    echo "New install"
    chown www-data.www-data -R /var/www/booked/tpl_c /var/www/booked/tpl /var/www/booked/Web/uploads
    
    # Sleep for a few seconds to give MySQL time to initialise
    echo "Waiting for MySQL to start - max 300 seconds"
    /usr/local/bin/wait-for-it.sh -q -t 300 mariadb:3306
    
    if [ ! "$?" == 0 ]
    then
      echo "MySQL didn't start in the allocated time" > /var/www/LOG
    fi
    
    # Safety sleep to give MySQL a moment to settle after coming up
    echo "MySQL started"
    sleep 1
    
    echo "Provisioning Database"
    if [ "$CREATE_DATABASE" == "yes" ]
    then
      # Create database
      mysql -u root -p$DB_ROOT_PASSWORD -h mariadb -e "CREATE DATABASE $DB_NAME"
      mysql -u root -p$DB_ROOT_PASSWORD -h mariadb -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '${DB_BOOKED_USER}'@'%' IDENTIFIED BY '$DB_BOOKED_PASSWORD'; FLUSH PRIVILEGES;"
    fi
    
    mysql -D $DB_NAME -u $DB_BOOKED_USER -p$DB_BOOKED_PASSWORD -h mariadb -e "SOURCE /var/www/booked/database_schema/create-schema.sql"
    mysql -D $DB_NAME -u $DB_BOOKED_USER -p$DB_BOOKED_PASSWORD -h mariadb -e "SOURCE /var/www/booked/database_schema/create-data.sql"
    
    # Write settings.php
    echo "Writing settings.php"
    cp /tmp/config.php-template /var/www/booked/config/config.php
    sed -i "s/#TIMEZONE#/${TIMEZONE}/" /var/www/booked/config/config.php
    sed -i "s/#ADMIN_MAIL#/${ADMIN_MAIL}/" /var/www/booked/config/config.php
    sed -i "s/#SCRIPT_URL#/${SCRIPT_URL}/" /var/www/booked/config/config.php
    sed -i "s/#DB_BOOKED_USER#/${DB_BOOKED_USER}/" /var/www/booked/config/config.php
    sed -i "s/#DB_BOOKED_PASSWORD#/${DB_BOOKED_PASSWORD}/" /var/www/booked/config/config.php
    sed -i "s/#DB_HOST#/${DB_HOST}/" /var/www/booked/config/config.php
    sed -i "s/#DB_NAME#/${DB_NAME}/" /var/www/booked/config/config.php
    sed -i "s/#SMTP_HOST#/${SMTP_SERVER}/" /var/www/booked/config/config.php
    sed -i "s/#SMTP_SECURE#/${SMTP_SECURE}/" /var/www/booked/config/config.php
    sed -i "s/#SMTP_USERNAME#/${SMTP_USERNAME}/" /var/www/booked/config/config.php
    sed -i "s/#SMTP_PASSWORD#/${SMTP_PASSWORD}/" /var/www/booked/config/config.php

    chmod 660 /var/www/booked/config/config.php
  fi
  
  # Remove the flag so we don't try and bootstrap in future
  rm /INSTALL-FLAG

fi

echo "Starting php-fpm"
exec "$@"

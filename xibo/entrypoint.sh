#!/bin/bash

# Detect if we're going to run an upgrade
if [ -e "/CMS-FLAG" ]
then
  if [ -e "/var/www/xibo/settings.php" ]
  then
    # Run a database backup
    dbuser=$(awk -F "'" '/dbuser =/ {print $2}' /var/www/xibo/settings.php)
    dbpass=$(awk -F "'" '/dbpass =/ {print $2}' /var/www/xibo/settings.php)
    dbname=$(awk -F "'" '/dbname =/ {print $2}' /var/www/xibo/settings.php)
    
    mysqldump -h mariadb -u $dbuser -p$dbpass $dbname | gzip > /var/www/backup/$(date +"%Y-%m-%d_%H-%M-%S").sql.gz

    # Backup the settings.php file
    mv /var/www/xibo/settings.php /tmp/settings.php
    
    # Delete the old install EXCEPT the library directory
    find /var/www/xibo ! -name library -type d -exec rm -rf {} \;
    find /var/www/xibo -type f -maxdepth 1 -exec rm -f {} \;

    # Replace settings
    mv /tmp/settings.php /var/www/xibo/settings.php
  fi
  
  # Drop the CMS cache (if it exists)
  if [ -d /var/www/xibo/cache ]
  then
    rm -r /var/www/xibo/cache
  fi

  tar --strip=1 -zxf /var/www/xibo-cms.tar.gz -C /var/www/xibo --exclude=settings.php

  chown www-data.www-data -R /var/www/xibo

  mkdir /var/www/xibo/cache
  mkdir -p /var/www/xibo/library/temp
  chown www-data.www-data -R /var/www/xibo/cache /var/www/xibo/library
  
  if [ ! -e "/var/www/xibo/settings.php" ]
  then
    # This is a fresh install so bootstrap the whole
    # system
    echo "New install"
    mkdir -p /var/www/xibo/cache
    mkdir -p /var/www/xibo/library/temp
    chown www-data.www-data -R /var/www/xibo/cache /var/www/xibo/library
    
    # Sleep for a few seconds to give MySQL time to initialise
    echo "Waiting for MySQL to start - max 300 seconds"
    /usr/local/bin/wait-for-it.sh -q -t 300 mariadb:3306
    
    if [ ! "$?" == 0 ]
    then
      echo "MySQL didn't start in the allocated time" > /var/www/backup/LOG
    fi
    
    # Safety sleep to give MySQL a moment to settle after coming up
    echo "MySQL started"
    sleep 1
    
    echo "Provisioning Database"
    if [ "$CREATE_DATABASE" == "yes" ]
    then
      # Create database
      mysql -u root -p$DB_ROOT_PASSWORD -h mariadb -e "CREATE DATABASE $DB_NAME"
      mysql -u root -p$DB_ROOT_PASSWORD -h mariadb -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '${DB_XIBO_USER}'@'%' IDENTIFIED BY '$DB_XIBO_PASSWORD'; FLUSH PRIVILEGES;"
    fi
    
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "SOURCE /var/www/xibo/install/master/structure.sql"
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "SOURCE /var/www/xibo/install/master/data.sql"
    # Write settings.php
    echo "Writing settings.php"
    SECRET_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    CMS_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    cp /tmp/settings.php-template /var/www/xibo/settings.php
    sed -i "s/\$dbpass = .*$/\$dbpass = '$DB_XIBO_PASSWORD';/" /var/www/xibo/settings.php
    sed -i "s/\$dbuser = .*$/\$dbuser = '$DB_XIBO_USER';/" /var/www/xibo/settings.php
    sed -i "s/\$dbname = .*$/\$dbname = '$DB_NAME';/" /var/www/xibo/settings.php

    sed -i "s/define('SECRET_KEY','');/define('SECRET_KEY','$SECRET_KEY');/" /var/www/xibo/settings.php

    echo "Configuring Database Settings"
    # Set LIBRARY_LOCATION
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "UPDATE \`setting\` SET \`value\`='/var/www/xibo/library/', \`userChange\`=0, \`userSee\`=0 WHERE \`setting\`='LIBRARY_LOCATION' LIMIT 1"

    # Set admin username/password
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "UPDATE \`user\` SET \`UserName\`='xibo_admin', \`UserPassword\`='5f4dcc3b5aa765d61d8327deb882cf99' WHERE \`UserID\` = 1 LIMIT 1"

    # Set CMS Key
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "UPDATE \`setting\` SET \`value\`='$CMS_KEY' WHERE \`setting\`='SERVER_KEY' LIMIT 1"
    
    # Configure Maintenance
    echo "Setting up Maintenance"
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "UPDATE \`setting\` SET \`value\`='Protected' WHERE \`setting\`='MAINTENANCE_ENABLED' LIMIT 1"

    MAINTENANCE_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    mysql -D $DB_NAME -u $DB_XIBO_USER -p$DB_XIBO_PASSWORD -h mariadb -e "UPDATE \`setting\` SET \`value\`='$MAINTENANCE_KEY' WHERE \`setting\`='MAINTENANCE_KEY' LIMIT 1"

    mkdir -p /var/www/backup/cron
    echo "*/5 * * * *   root  /usr/bin/wget -O /dev/null -o /dev/null http://ds.${DOMAIN}/maintenance.php?key=$MAINTENANCE_KEY" > /var/www/backup/cron/cms-maintenance
    
    # Remove the installer
    echo "Removing the installer"
    rm -f /var/www/xibo/install.php
    rm -Rf /var/www/xibo/install
  fi
  
  # Remove the flag so we don't try and bootstrap in future
  rm /CMS-FLAG

  # Ensure there's a group for ssmtp
  /usr/sbin/groupadd ssmtp
  
  # Ensure there's a crontab for maintenance
  cp /var/www/backup/cron/cms-maintenance /etc/cron.d/cms-maintenance
  
fi

# Configure SSMTP to send emails if required
/bin/sed -i "s/mailhub=.*$/mailhub=${SMTP_SERVER}:${SMTP_PORT}/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthUser=.*$/AuthUser=$SMTP_USERNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/AuthPass=.*$/AuthPass=$SMTP_PASSWORD/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseTLS=.*$/UseTLS=$XIBO_SMTP_USE_TLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/UseSTARTTLS=.*$/UseSTARTTLS=$XIBO_SMTP_USE_STARTTLS/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/rewriteDomain=.*$/rewriteDomain=$XIBO_SMTP_REWRITE_DOMAIN/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/hostname=.*$/hostname=$XIBO_SMTP_HOSTNAME/" /etc/ssmtp/ssmtp.conf
/bin/sed -i "s/FromLineOverride=.*$/FromLineOverride=$XIBO_SMTP_FROM_LINE_OVERRIDE/" /etc/ssmtp/ssmtp.conf

# Secure SSMTP files
# Following recommendations here:
# https://wiki.archlinux.org/index.php/SSMTP#Security
/bin/chgrp ssmtp /etc/ssmtp/ssmtp.conf
/bin/chgrp ssmtp /usr/sbin/ssmtp
/bin/chmod 640 /etc/ssmtp/ssmtp.conf
/bin/chmod g+s /usr/sbin/ssmtp

echo "Starting cron"
/usr/sbin/cron
/usr/sbin/anacron

echo "Starting php-fpm"
exec "$@"

#!/bin/bash
# (C) Campbell Software Solutions 2015
set -e

# Automate installation
php /usr/local/bin/install.php
echo Applying configuration file security
chmod 644 /var/www/osticket/include/ost-config.php

#Launch supervisor to manage processes
exec /usr/bin/supervisord -c /usr/local/etc/supervisord.conf

#!/bin/bash
set -e

DB_NAME=${DB}

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



if [ -f ./config/configuration.tmpl ]
then
  sed -i -e"s/{{SMTP_SERVER}}/${SMTP_SERVER}/" ./config/configuration.tmpl
  sed -i -e"s/{{DOMAIN}}/${DOMAIN}/" ./config/configuration.tmpl
  sed -i -e"s/{{USERNAME}}/${SMTP_USERNAME}/" ./config/configuration.tmpl
  sed -i -e"s/{{PASSWORD}}/${SMTP_PASSWORD}/" ./config/configuration.tmpl
  mv ./config/configuration.tmpl ./config/configuration.yml
fi

case "$1" in
	rails|rake|passenger)
		if [ ! -f './config/database.yml' ]; then
			if [ "$DB_TYPE_MYSQL" ]; then
				adapter='mysql2'
				host="$DB_HOST"
				: "${REDMINE_DB_PORT:=3306}"
				: "${REDMINE_DB_USERNAME:=${DB_USER:-root}}"
				: "${REDMINE_DB_PASSWORD:=${DB_PASSWORD}}"
				: "${REDMINE_DB_DATABASE:=${DB}}}"
				: "${REDMINE_DB_ENCODING:=}"
			fi

			REDMINE_DB_ADAPTER="$adapter"
			REDMINE_DB_HOST="$host"
			echo "$RAILS_ENV:" > config/database.yml
			for var in \
				adapter \
				host \
				port \
				username \
				password \
				database \
				encoding \
			; do
				env="REDMINE_DB_${var^^}"
				val="${!env}"
				[ -n "$val" ] || continue
				echo "  $var: \"$val\"" >> config/database.yml
			done
		fi

		# ensure the right database adapter is active in the Gemfile.lock
		bundle install --without development test

		if [ ! -s config/secrets.yml ]; then
			if [ "$REDMINE_SECRET_KEY_BASE" ]; then
				cat > 'config/secrets.yml' <<-YML
					$RAILS_ENV:
					  secret_key_base: "$REDMINE_SECRET_KEY_BASE"
				YML
			elif [ ! -f /usr/src/redmine/config/initializers/secret_token.rb ]; then
				rake generate_secret_token
			fi
		fi
		if [ "$1" != 'rake' -a -z "$REDMINE_NO_DB_MIGRATE" ]; then
			gosu redmine rake db:migrate
		fi

		chown -R redmine:redmine files log public/plugin_assets

		# remove PID file to enable restarting the container
		rm -f /usr/src/redmine/tmp/pids/server.pid

		if [ ! -d /usr/src/redmine/plugins/redmine_ics_export ]
		then
		    cd /usr/src/redmine/plugins
		    git clone https://github.com/buschmais/redmics.git redmine_ics_export
		    cd /usr/src/redmine
		    bundle install --without development test
		    rake redmine:plugins:migrate RAILS_ENV=production
		fi

		if [ ! -d /usr/src/redmine/plugins/redmine_omniauth_google ]
		then
		    cd /usr/src/redmine/plugins
		    git clone https://github.com/twinslash/redmine_omniauth_google.git
		    cd /usr/src/redmine
		    bundle install --without development test
		    rake redmine:plugins:migrate RAILS_ENV=production
		fi

		if [ ! -d /usr/src/redmine/plugins/redmine_login_attempts_limit ]
		then
		    cd /usr/src/redmine/plugins
		    git clone https://github.com/midnightSuyama/redmine_login_attempts_limit.git
		fi

		if [ "$1" = 'passenger' ]; then
			# Don't fear the reaper.
			set -- tini -- "$@"
		fi

		set -- gosu redmine "$@"
		;;
esac

exec "$@"

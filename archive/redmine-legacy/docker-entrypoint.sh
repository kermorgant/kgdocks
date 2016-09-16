#!/bin/bash
set -e

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
			adapter='postgresql'
			host='postgres'
			port="${POSTGRES_PORT_5432_TCP_PORT:-5432}"
			username="${DB_USER:-redmine}"
			password="${DB_PASSWORD}"
			database="${DB:-$username}"
			encoding=utf8
			cat > './config/database.yml' <<-YML
				$RAILS_ENV:
				  adapter: $adapter
				  database: $database
				  host: $host
				  username: $username
				  password: "$password"
				  encoding: $encoding
				  port: $port
			YML
		fi

		
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
      echo "here"
      cd /usr/src/redmine/plugins
      git clone https://github.com/buschmais/redmics.git redmine_ics_export
      cd /usr/src/redmine
      bundle install --without development test
      rake redmine:plugins:migrate RAILS_ENV=production
    fi	
    
    if [ ! -d /usr/src/redmine/plugins/redmine_omniauth_google ]
    then
      echo "here2"
      cd /usr/src/redmine/plugins
      git clone https://github.com/twinslash/redmine_omniauth_google.git
      cd /usr/src/redmine
      bundle install --without development test
      rake redmine:plugins:migrate RAILS_ENV=production
    fi    
		
		if [ "$1" = 'passenger' ]; then
			# Don't fear the reaper.
			set -- tini -- "$@"
		fi
		
		set -- gosu redmine "$@"
		;;
esac




exec "$@"


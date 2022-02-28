#!/bin/sh

function join_by {
	local d=${1-} f=${2-}
	if shift 2; then
		printf %s "$f" "${@/#/$d}"
	fi
}

# Make sure configuration directory is setup properly
if [ ! -d "/etc/pdns/conf.d" ]; then
	mkdir -p /etc/pdns/conf.d
fi
chown -R root:pdns /etc/pdns/conf.d
chmod 0750 /etc/pdns/conf.d
find /etc/pdns/conf.d -type f -name "*.conf" -print0 | xargs --no-run-if-empty -0 chmod 0660


echo "NOTICE: Setting up config"

# Setup server ID
if [ ! -f /etc/pdns/conf.d/10-server-id.conf ]; then
	if [ -z "$POWERDNS_SERVER_ID" ]; then
		echo "ERROR: Environment variable 'POWERDNS_SERVER_ID' is required'"
	fi
	cat <<EOF > /etc/pdns/conf.d/10-server-id.conf
server-id = $POWERDNS_SERVER_ID
EOF
fi

# Not sure what to do about this?
#enable-lua-records=yes/shared

# Setup defaults
if [ ! -f /etc/pdns/conf.d/40-defaults.conf ]; then
cat <<EOF > /etc/pdns/conf.d/40-defaults.conf
max-tcp-connection-duration=5
max-tcp-connections=1024
max-tcp-connections-per-client=4

max-queue-length=16384
overload-queue-length=4096

query-cache-ttl=59
EOF
fi

# If we have no PostgreSQL setup, check if we can add it
if [ ! -f /etc/pdns/conf.d/50-backend-gpgsql.conf ]; then
	# This will depend if we have POSTGRES_DATABASE set
	if [ -n "$POSTGRES_DATABASE" ]; then
		# Check for a few things we need
		if [ -z "$POSTGRES_HOST" ]; then
			echo "ERROR: Environment variable 'POSTGRES_HOST' is required"
			exit 1
		fi
		if [ -z "$POSTGRES_USER" ]; then
			echo "ERROR: Environment variable 'POSTGRES_USER' is required"
			exit 1
		fi
		if [ -z "$POSTGRES_USER_PASSWORD" ]; then
			echo "ERROR: Environment variable 'POSTGRES_USER_PASSWORD' is required"
			exit 1
		fi
		# Output config
		cat <<EOF > /etc/pdns/conf.d/50-backend-gpgsql.conf
launch += gpgsql
gpgsql-dbname = $POSTGRES_DATABASE
gpgsql-host = $POSTGRES_HOST
gpgsql-user = $POSTGRES_USER
gpgsql-password = $POSTGRES_USER_PASSWORD
gpgsql-dnssec = yes
EOF
		# Setup perms
		chown root:pdns /etc/pdns/conf.d/50-backend-gpgsql.conf
		chmod 0640 /etc/pdns/conf.d/50-backend-gpgsql.conf

		# Signal to init postgresql
		INIT_POSTGRESQL=1
	fi
fi


# If we have no MySQL setup, check if we can add it
if [ ! -f /etc/pdns/conf.d/50-backend-gmysql.conf ]; then
	# This will depend if we have MYSQL_DATABASE set
	if [ -n "$MYSQL_DATABASE" ]; then
		# Check for a few things we need
		if [ -z "$MYSQL_HOST" ]; then
			echo "ERROR: Environment variable 'MYSQL_HOST' is required"
			exit 1
		fi
		if [ -z "$MYSQL_USER" ]; then
			echo "ERROR: Environment variable 'MYSQL_USER' is required"
			exit 1
		fi
		if [ -z "$MYSQL_PASSWORD" ]; then
			echo "ERROR: Environment variable 'MYSQL_PASSWORD' is required"
			exit 1
		fi
		# Output config
		cat <<EOF > /etc/pdns/conf.d/50-backend-gmysql.conf
launch += gmysql
gmysql-dbname = $MYSQL_DATABASE
gmysql-host = $MYSQL_HOST
gmysql-user = $MYSQL_USER
gmysql-password = $MYSQL_PASSWORD
gmysql-dnssec = yes
EOF
		# Setup perms
		chown root:pdns /etc/pdns/conf.d/50-backend-gmysql.conf
		chmod 0640 /etc/pdns/conf.d/50-backend-gmysql.conf

		# Signal to init MYSQLql
		INIT_MYSQL=1
	fi
fi


if [ -n "$POSTGRES_DATABASE" ]; then
	while true; do
		echo "NOTICE: Waiting for PostgreSQL server '$POSTGRES_HOST'..."
		pg_isready -d "$POSTGRES_DATABASE" -h "$POSTGRES_HOST" -U "$POSTGRES_USER" && break || true
		sleep 1
	done
fi

if [ -n "$MYSQL_DATABASE" ]; then
	while true; do
		echo "NOTICE: Waiting for MySQL server '$MYSQL_HOST'..."
		mysqladmin ping -h "$MYSQL_HOST" --silent --connect-timeout=2 && break || true
		sleep 1
	done
fi


if [ -n "$INIT_POSTGRESQL" ]; then
	echo "NOTICE: Initializing PostgreSQL database"
	export PGPASSWORD="$POSTGRES_USER_PASSWORD"
	psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -w "$POSTGRES_DATABASE" -v ON_ERROR_STOP=ON < /usr/share/doc/pdns/schema.pgsql.sql
	unset PGPASSWORD
fi

if [ -n "$INIT_MYSQL" ]; then
	echo "NOTICE: Initializing MySQL database"
	export MYSQL_PWD="$MYSQL_PASSWORD"
	mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE" < /usr/share/doc/pdns/schema.mysql.sql
	unset MYSQL_PWD
fi


# Setup web access
if [ ! -f /etc/pdns/conf.d/50-webserver.conf ]; then
	# Check for access rule
	if [ -n "$POWERDNS_WEBSERVER_ALLOW_FROM" ]; then
		# Check if we got a password
		if [ -z "$POWERDNS_WEBSERVER_PASSWORD" ]; then
			POWERDNS_WEBSERVER_PASSWORD=`pwgen 16 1`
			echo "NOTICE: Webserver password: $POWERDNS_WEBSERVER_PASSWORD"
		fi
		# Check if we got a API key
		if [ -z "$POWERDNS_API_KEY" ]; then
			POWERDNS_API_KEY=`pwgen 16 1`
			echo "NOTICE: Webserver API key: $POWERDNS_API_KEY"
		fi

		cat <<EOF > /etc/pdns/conf.d/50-webserver.conf
webserver = yes
webserver-address = 0.0.0.0
webserver-allow-from = $POWERDNS_WEBSERVER_ALLOW_FROM
webserver-loglevel = normal
webserver-password = $POWERDNS_WEBSERVER_PASSWORD
webserver-port=8081
api = yes
api-key = $POWERDNS_API_KEY
EOF
	fi
fi


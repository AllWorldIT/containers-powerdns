#!/bin/bash
# Copyright (c) 2022-2023, AllWorldIT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


fdc_notice "Setting up PowerDNS permissions"

# Setup run directory
if [ ! -d /run/powerdns ]; then
	mkdir -p /run/powerdns
fi
chown -R powerdns:powerdns /run/powerdns
chmod 0755 /run/powerdns

# Make sure configuration directory is setup properly
if [ ! -d "/etc/powerdns/conf.d" ]; then
	mkdir -p /etc/powerdns/conf.d
fi
chown -R root:powerdns /etc/powerdns/conf.d
chmod 0750 /etc/powerdns/conf.d
find /etc/powerdns/conf.d -type f -name "*.conf" -print0 | xargs --no-run-if-empty -0 chmod 0640


fdc_notice "Initializing PowerDNS settings"


# Setup server ID
if [ ! -f /etc/powerdns/conf.d/10-server-id.conf ]; then
	if [ -z "$POWERDNS_SERVER_ID" ]; then
		fdc_error "PowerDNS environment variable 'POWERDNS_SERVER_ID' is required'"
	fi
	cat <<EOF > /etc/powerdns/conf.d/10-server-id.conf
server-id = $POWERDNS_SERVER_ID
EOF
fi


# Setup defaults
if [ ! -f /etc/powerdns/conf.d/40-defaults.conf ]; then
	cat <<EOF > /etc/powerdns/conf.d/40-defaults.conf
max-tcp-connection-duration=5
max-tcp-connections=1024
max-tcp-connections-per-client=4

max-queue-length=16384
overload-queue-length=4096

query-cache-ttl=59

reuseport=yes
EOF
fi


# Check if we have a default SOA content set
if [ ! -f /etc/powerdns/conf.d/42-soa-default.conf ] && [ -n "$POWERDNS_DEFAULT_SOA_CONTENT" ]; then
	echo -e "\ndefault-soa-content=$POWERDNS_DEFAULT_SOA_CONTENT" >> /etc/powerdns/conf.d/42-soa-default.conf
fi


# Check if we need to do backend config
if [ ! -f /etc/powerdns/conf.d/50-backend.conf ]; then

	# If we have no PostgreSQL setup, check if we can add it
	if [ -n "$POSTGRES_DATABASE" ]; then
		# Check for a few things we need
		if [ -z "$POSTGRES_HOST" ]; then
			fdc_error "PowerDNS environment variable 'POSTGRES_HOST' is required"
			false
		fi
		if [ -z "$POSTGRES_USER" ]; then
			fdc_error "PowerDNS environment variable 'POSTGRES_USER' is required"
			false
		fi
		if [ -z "$POSTGRES_PASSWORD" ]; then
			fdc_error "PowerDNS environment variable 'POSTGRES_PASSWORD' is required"
			false
		fi

		# Output config
		cat <<EOF > /etc/powerdns/conf.d/50-backend.conf
launch += gpgsql
gpgsql-dbname = $POSTGRES_DATABASE
gpgsql-host = $POSTGRES_HOST
gpgsql-user = $POSTGRES_USER
gpgsql-password = $POSTGRES_PASSWORD
gpgsql-dnssec = yes
EOF
	fi


	# If we have no MySQL setup, check if we can add it
	if [ -n "$MYSQL_DATABASE" ]; then
		# Check for a few things we need
		if [ -z "$MYSQL_HOST" ]; then
			fdc_error "PowerDNS environment variable 'MYSQL_HOST' is required"
			false
		fi
		if [ -z "$MYSQL_USER" ]; then
			fdc_error "PowerDNS environment variable 'MYSQL_USER' is required"
			false
		fi
		if [ -z "$MYSQL_PASSWORD" ]; then
			fdc_error "PowerDNS environment variable 'MYSQL_PASSWORD' is required"
			false
		fi

		# Output config
		cat <<EOF > /etc/powerdns/conf.d/50-backend.conf
launch += gmysql
gmysql-dbname = $MYSQL_DATABASE
gmysql-host = $MYSQL_HOST
gmysql-user = $MYSQL_USER
gmysql-password = $MYSQL_PASSWORD
gmysql-dnssec = yes
EOF
	fi

	# If we have a remote connection, check if we can configure it
	if [ -n "$POWERDNS_REMOTE_CONNECTION_STRING" ]; then
		# Output config
		cat <<EOF > /etc/powerdns/conf.d/50-backend.conf
remote-connection-string=$POWERDNS_REMOTE_CONNECTION_STRING
EOF
	fi
fi

# Setup perms
if [ -e /etc/powerdns/conf.d/50-backend.conf ]; then
	chown root:powerdns /etc/powerdns/conf.d/50-backend.conf
	chmod 0640 /etc/powerdns/conf.d/50-backend.conf
fi


# Setup web access
if [ ! -f /etc/powerdns/conf.d/52-webserver.conf ] && [ -n "$POWERDNS_WEBSERVER_ALLOW_FROM" ]; then
	# Check if we got a password
	if [ -z "$POWERDNS_WEBSERVER_PASSWORD" ]; then
		POWERDNS_WEBSERVER_PASSWORD=$(pwgen 16 1)
		fdc_notice "PowerDNS webserver password: $POWERDNS_WEBSERVER_PASSWORD"
	fi
	# Check if we got a API key
	if [ -z "$POWERDNS_API_KEY" ]; then
		POWERDNS_API_KEY=$(pwgen 16 1)
		fdc_notice "PowerDNS webserver API key: $POWERDNS_API_KEY"
	fi

	cat <<EOF > /etc/powerdns/conf.d/50-webserver.conf
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


# Check if we're enabling LUA records
if [ ! -f /etc/powerdns/conf.d/60-lua-records.conf ] && [ -n "$POWERDNS_ENABLE_LUA_RECORDS" ]; then
	echo "enable-lua-records = yes" > /etc/powerdns/conf.d/60-lua-records.conf
fi


# Check if we're expanding ALIAS records
if [ ! -f /etc/powerdns/conf.d/60-expand-alias.conf ] && [ -n "$POWERDNS_EXPAND_ALIAS" ]; then
	cat <<EOF > /etc/powerdns/conf.d/60-expand-alias.conf
resolver = $POWERDNS_EXPAND_ALIAS
expand-alias = yes
EOF
fi


if [ -n "$POSTGRES_DATABASE" ]; then
	export PGPASSWORD="$POSTGRES_PASSWORD"

	while true; do
		fdc_notice "PowerDNS waiting for PostgreSQL server '$POSTGRES_HOST'..."
		if pg_isready -d "$POSTGRES_DATABASE" -h "$POSTGRES_HOST" -U "$POSTGRES_USER"; then
			break
		fi
		sleep 1
	done

	# Check if the domain table exists, if not, create the database
	if echo "\dt domains" | psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -w "$POSTGRES_DATABASE" -v ON_ERROR_STOP=ON  2>&1 | grep -q 'Did not find any relation named "domains"'; then
		fdc_notice "Initializing PowerDNS PostgreSQL database"
		psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -w "$POSTGRES_DATABASE" -v ON_ERROR_STOP=ON < /usr/share/doc/pdns/schema.pgsql.sql
	fi

	unset PGPASSWORD
fi

if [ -n "$MYSQL_DATABASE" ]; then
	export MYSQL_PWD="$MYSQL_PASSWORD"

	while true; do
		fdc_notice "PowerDNS waiting for MySQL server '$MYSQL_HOST'..."
		if mysqladmin ping --host "$MYSQL_HOST" --user "$MYSQL_USER" --silent --connect-timeout=2; then
			fdc_notice "MySQL server is UP, continuing"
			break
		fi
		sleep 1
	done

	# Check if clustering is enabled
	if echo "SHOW GLOBAL STATUS LIKE 'wsrep_connected';" | mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE" -s | grep -q "ON"; then
		fdc_notice "PowerDNS is running on a MySQL cluster, waiting for it to accept queries"
		while true; do
			fdc_notice "PowerDNS waiting for MySQL cluster to accept queries..."
			if echo "SHOW GLOBAL STATUS LIKE 'wsrep_ready';" | mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE" -s | grep -q "ON"; then
				fdc_notice "MySQL cluster can accept queries, continuing"
				break
			fi
			sleep 1
		done
	fi

	# Check if the domain table exists, if not, create the database
	if ! echo "SHOW CREATE TABLE domains;" | mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE" > /dev/null 2>&1; then
		fdc_notice "Initializing PowerDNS MySQL database"

		mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE" < /usr/share/doc/pdns/schema.mysql.sql
		# We should add foreign keys as per https://doc.powerdns.com/authoritative/backends/generic-mysql.html
		cat <<EOF | mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" "$MYSQL_DATABASE"
ALTER TABLE records ADD CONSTRAINT records_domain_id_ibfk FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE comments ADD CONSTRAINT comments_domain_id_ibfk FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE domainmetadata ADD CONSTRAINT domainmetadata_domain_id_ibfk FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE cryptokeys ADD CONSTRAINT cryptokeys_domain_id_ibfk FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE ON UPDATE CASCADE;
EOF
	fi

	unset MYSQL_PWD
fi


# Set default health check query
if [ -z "$POWERDNS_HEALTHCHECK_QUERY" ]; then
	# shellcheck disable=SC2034
	POWERDNS_HEALTHCHECK_QUERY="id.server CHAOS TXT"
fi
# Write out environment and fix perms of the config file
set | grep -E '^POWERDNS_HEALTHCHECK_QUERY' > /etc/powerdns/powerdns.env
chown root:powerdns /etc/powerdns/powerdns.env
chmod 0640 /etc/powerdns/powerdns.env
# NK: Unset so we force the env load in CI testing
unset POWERDNS_HEALTHCHECK_QUERY

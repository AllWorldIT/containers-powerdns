FROM registry.gitlab.iitsp.com/allworldit/docker/alpine:latest

ARG VERSION_INFO=
LABEL maintainer="Nigel Kukard <nkukard@lbsd.net>"

RUN set -ex; \
	true "MariaDB Client"; \
	apk add --no-cache mariadb-client; \
	true "PostgreSQL Client"; \
	apk add --no-cache postgresql-client; \
	true "PowerDNS"; \
	apk add --no-cache \
		pdns \
		pdns-backend-bind \
		pdns-backend-geoip \
		pdns-backend-ldap \
		pdns-backend-lua2 \
		pdns-backend-mariadb \
		pdns-backend-pgsql \
		pdns-backend-pipe \
		pdns-backend-remote \
		pdns-backend-sqlite3 \
		pdns-doc \
		; \
	true "Tools"; \
	apk add --no-cache \
		bind-tools \
		pwgen \
		; \
	true "Versioning"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*

RUN set -ex; \
	true "Creating runtime directories"; \
	mkdir -p /run/pdns; \
	chown -R pdns:pdns /run/pdns; \
	chmod 2777 /run/pdns

RUN set -ex; \
	true "Setup configuration"; \
	mkdir -p /etc/pdns/conf.d; \
	rm /etc/pdns/4.1.0_to_4.2.0_schema.pgsql.sql; \
	sed -ri "s!^#?\s*(disable-syslog)\s*=\s*\S*.*!\1 = yes!" /etc/pdns/pdns.conf; \
	grep -E "^disable-syslog = yes$" /etc/pdns/pdns.conf; \
	sed -ri "s!^#?\s*(include-dir)\s*=\s*\S*.*!\1 = /etc/pdns/conf.d!" /etc/pdns/pdns.conf; \
	grep -E "^include-dir = /etc/pdns/conf\.d$" /etc/pdns/pdns.conf; \
	sed -ri "s!^#?\s*(launch)\s*=\s*\S*.*!\1 =!" /etc/pdns/pdns.conf; \
	grep -E "^launch =$" /etc/pdns/pdns.conf; \
	sed -ri "s!^#?\s*(socket-dir)\s*=\s*\S*.*!\1 = /run/pdns!" /etc/pdns/pdns.conf; \
	grep -E "^socket-dir = /run/pdns$" /etc/pdns/pdns.conf; \
	sed -ri "s!^#?\s*(version-string)\s*=\s*\S*.*!\1 = anonymous!" /etc/pdns/pdns.conf; \
	grep -E "^version-string = anonymous$" /etc/pdns/pdns.conf; \
	chmod 0750 /etc/pdns; \
	chmod 0640 /etc/pdns/pdns.conf; \
	chown -R root:pdns /etc/pdns


# PowerDNS
COPY etc/supervisor/conf.d/powerdns.conf /etc/supervisor/conf.d/powerdns.conf
COPY init.d/50-powerdns.sh /docker-entrypoint-init.d/50-powerdns.sh
COPY pre-init-tests.d/50-powerdns.sh /docker-entrypoint-pre-init-tests.d/50-powerdns.sh
COPY tests.d/50-powerdns.sh /docker-entrypoint-tests.d/50-powerdns.sh
RUN set -ex; \
	chown root:root \
		/etc/supervisor/conf.d/powerdns.conf \
		/docker-entrypoint-init.d/50-powerdns.sh \
		/docker-entrypoint-pre-init-tests.d/50-powerdns.sh \
		/docker-entrypoint-tests.d/50-powerdns.sh; \
	chmod 0644 \
		/etc/supervisor/conf.d/powerdns.conf; \
	chmod 0755 \
		/docker-entrypoint-init.d/50-powerdns.sh \
		/docker-entrypoint-pre-init-tests.d/50-powerdns.sh \
		/docker-entrypoint-tests.d/50-powerdns.sh


EXPOSE 53/TCP 53/UDP
EXPOSE 8081


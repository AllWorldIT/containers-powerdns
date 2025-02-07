# Copyright (c) 2022-2025, AllWorldIT.
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


#
# We use a builder to build powerdns
#


FROM registry.conarx.tech/containers/alpine/edge as builder


ENV POWERDNS_VER=4.9.4


# Install libs we need
RUN set -eux; \
	true "Installing build dependencies"; \
	apk add --no-cache \
		build-base \
		\
		boost-dev curl curl-dev geoip-dev krb5-dev openssl-dev \
		libsodium-dev lua-dev mariadb-connector-c-dev openldap-dev \
		libpq-dev protobuf-dev sqlite-dev unixodbc-dev \
		yaml-cpp-dev zeromq-dev mariadb-dev luajit-dev libmaxminddb-dev \
		\
		lmdb-dev

# Download packages
RUN set -eux; \
	mkdir -p build; \
	cd build; \
	wget "https://downloads.powerdns.com/releases/pdns-${POWERDNS_VER}.tar.bz2"; \
	tar -jxf "pdns-${POWERDNS_VER}.tar.bz2"


# Build and install PowerDNS
RUN set -eux; \
	cd build; \
	cd "pdns-${POWERDNS_VER}"; \
	# Compiler flags
	. /etc/buildflags; \
	\
	./configure \
		--prefix=/usr \
		--sysconfdir="/etc/powerdns" \
		--sbindir=/usr/sbin \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--localstatedir=/var \
		--libdir="/usr/lib/powerdns" \
		--disable-static \
		--with-modules="" \
		--with-dynmodules="bind geoip gmysql godbc gpgsql gsqlite3 ldap lmdb lua2 pipe remote" \
		--with-libsodium \
		--enable-tools \
		--enable-ixfrdist \
		--enable-dns-over-tls \
		--disable-dependency-tracking \
		--disable-silent-rules \
		--enable-reproducible \
		--enable-unit-tests \
		--with-service-user=powerdns \
		--with-service-group=powerdns \
		--enable-remotebackend-http \
		--enable-remotebackend-zeromq; \
	make V=1 -j$(nproc) -l8; \
	\
	pkgdir=/build/powerdns-root; \
	make DESTDIR="$pkgdir" install; \
	\
# Move some things around
	mv "$pkgdir"/etc/powerdns/pdns.conf-dist "$pkgdir"/etc/powerdns/pdns.conf; \
	mv "$pkgdir"/etc/powerdns/ixfrdist.example.yml "$pkgdir"/usr/share/doc/pdns/; \
# Remove cruft
	find "$pkgdir" -type f -name "*.a" -o -name "*.la" | xargs rm -fv; \
	rm -rfv \
		"$pkgdir"/usr/include \
		"$pkgdir"/usr/share/man


RUN set -eux; \
	cd build/powerdns-root; \
	scanelf --recursive --nobanner --osabi --etype "ET_DYN,ET_EXEC" .  | awk '{print $3}' | xargs \
		strip \
			--remove-section=.comment \
			--remove-section=.note \
			-R .gnu.lto_* -R .gnu.debuglto_* \
			-N __gnu_lto_slim -N __gnu_lto_v1 \
			--strip-unneeded



#
# Build final image
#



FROM registry.conarx.tech/containers/alpine/edge


ARG VERSION_INFO=
LABEL org.opencontainers.image.authors   = "Nigel Kukard <nkukard@conarx.tech>"
LABEL org.opencontainers.image.version   = "edge"
LABEL org.opencontainers.image.base.name = "registry.conarx.tech/containers/alpine/edge"


# Copy in built binaries
COPY --from=builder /build/powerdns-root /


RUN set -eux; \
	true "PowerDNS requirements"; \
	apk add --no-cache \
		boost-libs \
		geoip \
		libcurl \
		libldap \
		libpq \
		libmaxminddb-libs \
		lmdb \
		luajit \
		mariadb-client \
		mariadb-connector-c \
		postgresql-client \
		pwgen \
		sqlite \
		unixodbc \
		yaml-cpp \
		zeromq \
		; \
	true "Setup user and group"; \
	addgroup -S powerdns 2>/dev/null; \
	adduser -S -D -h /var/lib/powerdns -s /sbin/nologin -G powerdns -g powerdns powerdns 2>/dev/null; \
	\
	true "Tools"; \
	apk add --no-cache \
		bind-tools \
		; \
	true "Cleanup"; \
	rm -f /var/cache/apk/*


RUN set -eux; \
	true "Setup configuration"; \
	mkdir -p /etc/powerdns/conf.d; \
	sed -ri "s!^#?\s*(disable-syslog)\s*=\s*\S*.*!\1 = yes!" /etc/powerdns/pdns.conf; \
	grep -E "^disable-syslog = yes$" /etc/powerdns/pdns.conf; \
	sed -ri "s!^#?\s*(log-timestamp)\s*=\s*\S*.*!\1 = yes!" /etc/powerdns/pdns.conf; \
	grep -E "^log-timestamp = yes$" /etc/powerdns/pdns.conf; \
	sed -ri "s!^#?\s*(include-dir)\s*=\s*\S*.*!\1 = /etc/powerdns/conf.d!" /etc/powerdns/pdns.conf; \
	grep -E "^include-dir = /etc/powerdns/conf\.d$" /etc/powerdns/pdns.conf; \
	sed -ri "s!^#?\s*(launch)\s*=\s*\S*.*!\1 =!" /etc/powerdns/pdns.conf; \
	grep -E "^launch =$" /etc/powerdns/pdns.conf; \
	sed -ri "s!^#?\s*(socket-dir)\s*=\s*\S*.*!\1 = /run/powerdns!" /etc/powerdns/pdns.conf; \
	grep -E "^socket-dir = /run/powerdns$" /etc/powerdns/pdns.conf; \
	sed -ri "s!^#?\s*(version-string)\s*=\s*\S*.*!\1 = anonymous!" /etc/powerdns/pdns.conf; \
	grep -E "^version-string = anonymous$" /etc/powerdns/pdns.conf; \
	chmod 0750 /etc/powerdns; \
	chmod 0640 /etc/powerdns/pdns.conf; \
	chown -R root:powerdns /etc/powerdns


# PowerDNS
COPY etc/supervisor/conf.d/powerdns.conf /etc/supervisor/conf.d/powerdns.conf
COPY usr/local/share/flexible-docker-containers/init.d/42-powerdns.sh /usr/local/share/flexible-docker-containers/init.d
COPY usr/local/share/flexible-docker-containers/pre-init-tests.d/42-powerdns.sh /usr/local/share/flexible-docker-containers/pre-init-tests.d
COPY usr/local/share/flexible-docker-containers/pre-init-tests.d/43-powerdns-zonefile.sh /usr/local/share/flexible-docker-containers/pre-init-tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/42-powerdns-mysql.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/42-powerdns-postgres.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/43-powerdns.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/local/share/flexible-docker-containers/tests.d/99-powerdns.sh /usr/local/share/flexible-docker-containers/tests.d
COPY usr/local/share/flexible-docker-containers/healthcheck.d/42-powerdns.sh /usr/local/share/flexible-docker-containers/healthcheck.d
RUN set -eux; \
	true "Flexible Docker Containers"; \
	if [ -n "$VERSION_INFO" ]; then echo "$VERSION_INFO" >> /.VERSION_INFO; fi; \
	true "Permissions"; \
	chown root:root \
		/etc/supervisor/conf.d/powerdns.conf; \
	chmod 0644 \
		/etc/supervisor/conf.d/powerdns.conf; \
	fdc set-perms


EXPOSE 53/TCP 53/UDP

EXPOSE 8081


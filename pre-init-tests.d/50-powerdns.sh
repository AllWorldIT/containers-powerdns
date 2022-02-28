#!/bin/sh

export POWERDNS_SERVER_ID=test.example.net

cat <<EOF > /etc/pdns/conf.d/50-test.conf
launch+=bind
bind-config=/etc/pdns/named.conf
EOF

cat <<EOF > /etc/pdns/named.conf
zone "example.com" {
	type master;
	file "/etc/pdns/named.zones/example.com";
};
EOF

mkdir /etc/pdns/named.zones
cat<<EOF > /etc/pdns/named.zones/example.com
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
powerdns IN      TXT    "WORKING"
EOF


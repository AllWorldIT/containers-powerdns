#!/bin/sh


# If we're not running the zonefile CI test, just return
[ "$CI" = "zonefile" ] || return 0


#
# As the zonefile requires config changes we have this in the pre-init-tests.d
#

cat <<EOF > /etc/powerdns/conf.d/50-test.conf
launch+=bind
bind-config=/etc/powerdns/named.conf
EOF

cat <<EOF > /etc/powerdns/named.conf
zone "example.com" {
	type master;
	file "/etc/powerdns/named.zones/example.com";
};
EOF

mkdir /etc/powerdns/named.zones
cat<<EOF > /etc/powerdns/named.zones/example.com
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


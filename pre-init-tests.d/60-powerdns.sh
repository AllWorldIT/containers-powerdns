#!/bin/sh

export POWERDNS_SERVER_ID=test.example.net

# Enable some debugging options
cat <<EOF > /etc/powerdns/conf.d/99-ci-testing.conf
log-dns-details=yes
log-dns-queries=yes
loglevel=3

EOF
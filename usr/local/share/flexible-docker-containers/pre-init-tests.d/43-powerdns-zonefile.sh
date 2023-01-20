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


# If we're not running the zonefile CI test, just return
if [ "$FDC_CI" != "zonefile" ]; then
  return
fi

fdc_notice "Setting up PowerDNS Zonefile test environment"

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


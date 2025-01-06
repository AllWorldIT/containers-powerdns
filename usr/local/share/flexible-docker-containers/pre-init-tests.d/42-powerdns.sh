#!/bin/bash
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


fdc_notice "Setting up PowerDNS test environment"

apk add curl

# shellcheck disable=SC2034
POWERDNS_SERVER_ID=test.example.net

# shellcheck disable=SC2034
POWERDNS_WEBSERVER_ALLOW_FROM=::ffff:127.0.0.1,::1
# shellcheck disable=SC2034
POWERDNS_WEBSERVER_PASSWORD=cipassword
# shellcheck disable=SC2034
POWERDNS_API_KEY=ciapikey

# Enable some debugging options
cat <<EOF > /etc/powerdns/conf.d/99-ci-testing.conf
log-dns-details=yes
log-dns-queries=yes
loglevel=3

EOF

# If we're run in the default FDC_CI test mode, change to using zonefile
if [ "$FDC_CI" = "true" ]; then
	FDC_CI="zonefile"
fi

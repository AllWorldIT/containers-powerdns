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


fdc_test_start powerdns "Testing DNS query result using IPv4"
if ! dig TXT powerdns.example.com @127.0.0.1 | grep WORKING; then
	fdc_test_fail powerdns "Failed to get correct DNS query reply using IPv4"
	false
fi
fdc_test_pass powerdns "Correct DNS query reply from PowerDNS using IPv4"


fdc_test_start powerdns "Check PowerDNS webserver is NOT responding using IPv4 and no authentication..."
if curl --verbose --fail --ipv4 "http://localhost:8081/metrics"; then
	fdc_test_fail powerdns "PowerDNS webserver is responding without authentication using IPv4"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver is responding using IPv4..."
if ! curl --verbose --fail --user "user:$POWERDNS_WEBSERVER_PASSWORD" --ipv4 "http://localhost:8081/metrics"; then
	fdc_test_fail powerdns "Failed to get data from PowerDNS webserver using IPv4"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver API is NOT responding using IPv4 and no authentication..."
if curl --verbose --fail --ipv4 "http://localhost:8081/api/v1/servers/localhost/statistics"; then
	fdc_test_fail powerdns "PowerDNS webserver API is responding without authentication using IPv4"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver API is responding using IPv4..."
if ! curl --verbose --fail -H "X-API-Key: $POWERDNS_API_KEY" --ipv4 "http://localhost:8081/api/v1/servers/localhost/statistics"; then
	fdc_test_fail powerdns "Failed to get data from PowerDNS webserver API using IPv4"
	false
fi



# Return if we don't have IPv6 support
if [ -z "$(ip -6 route show default)" ]; then
	fdc_test_alert powerdns "Not running IPv6 tests due to no IPv6 default route"
	return
fi



fdc_test_start powerdns "Check PowerDNS webserver is NOT responding using IPv6 and no authentication..."
if curl --verbose --fail --ipv6 "http://localhost:8081/metrics"; then
	fdc_test_fail powerdns "PowerDNS webserver is responding without authentication using IPv6"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver is responding using IPv6..."
if ! curl --verbose --fail --user "user:$POWERDNS_WEBSERVER_PASSWORD" --ipv6 "http://localhost:8081/metrics"; then
	fdc_test_fail powerdns "Failed to get data from PowerDNS webserver using IPv6"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver API is NOT responding using IPv6 and no authentication..."
if curl --verbose --fail --ipv6 "http://localhost:8081/api/v1/servers/localhost/statistics"; then
	fdc_test_fail powerdns "PowerDNS webserver API is responding without authentication using IPv6"
	false
fi

fdc_test_start powerdns "Check PowerDNS webserver API is responding using IPv6..."
if ! curl --verbose --fail -H "X-API-Key: $POWERDNS_API_KEY" --ipv6 "http://localhost:8081/api/v1/servers/localhost/statistics"; then
	fdc_test_fail powerdns "Failed to get data from PowerDNS webserver API using IPv6"
	false
fi

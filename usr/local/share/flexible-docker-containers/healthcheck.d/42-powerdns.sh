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


# Import settings
set -a
# shellcheck disable=SC1091
. /etc/powerdns/powerdns.env
set +a


# shellcheck disable=SC2086
POWERDNS_TEST_RESULT_IPV4=$(dig $POWERDNS_HEALTHCHECK_QUERY @127.0.0.1 2>&1)
if ! grep "status: NOERROR" <<< "$POWERDNS_TEST_RESULT_IPV4"; then
	fdc_error "Health check failed for PowerDNS using '$POWERDNS_HEALTHCHECK_QUERY' over IPv4:\n$POWERDNS_TEST_RESULT"
	false
fi
if [ -n "$FDC_CI" ]; then
	fdc_info "Health check for PowerDNS:\n$POWERDNS_TEST_RESULT_IPV4"
fi


# Return if we don't have IPv6 support
if [ -z "$(ip -6 route show default)" ]; then
	return
fi


# shellcheck disable=SC2086
POWERDNS_TEST_RESULT_IPV6=$(dig $POWERDNS_HEALTHCHECK_QUERY @::1 2>&1)
if ! grep "status: NOERROR" <<< "$POWERDNS_TEST_RESULT_IPV6"; then
	fdc_error "Health check failed for PowerDNS using '$POWERDNS_HEALTHCHECK_QUERY' over IPv6:\n$POWERDNS_TEST_RESULT"
	false
fi
if [ -n "$FDC_CI" ]; then
	fdc_info "Health check for PowerDNS:\n$POWERDNS_TEST_RESULT_IPV6"
fi

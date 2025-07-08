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


# If we're not running the PostgreSQL CI test, just return
if [ "$FDC_CI" != "postgresql" ]; then
	return
fi


fdc_test_start powerdns "Creating PowerDNS PostgreSQL test data using pdnsutil..."
if ! pdnsutil create-zone example.com ns.example.com; then
	fdc_test_fail powerdns "Failed to create PowerDNS PostgreSQL zone"
	false
fi
if ! pdnsutil add-record example.com powerdns TXT WORKING; then
	fdc_test_fail powerdns "Failed to add record to PowerDNS PostgreSQL zone"
	false
fi
if ! pdnsutil check-zone example.com; then
	fdc_test_fail powerdns "Failed to checking PowerDNS PostgreSQL zone"
	false
fi
if ! pdns_control rediscover; then
	fdc_test_fail powerdns "Failed rediscover for PowerDNS PostgreSQL zone"
	false
fi
fdc_test_pass powerdns "PowerDNS PostgreSQL test data created"

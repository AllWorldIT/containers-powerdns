#!/bin/sh


if ! dig TXT powerdns.example.com @127.0.0.1 | grep WORKING; then
	echo "CHECK FAILED (powerdns): Failed to get correct reply to powerdns.example.com"
	false
fi

touch /var/lib/powerdns/POWERDNS_CI_PASSED1


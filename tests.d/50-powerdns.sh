#!/bin/sh

if ! dig TXT powerdns.example.com @127.0.0.1 | grep WORKING; then
	echo "CHECK FAILED (powerdns): Not replying to powerdns.example.com"
	false
fi

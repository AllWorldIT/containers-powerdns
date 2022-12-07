#!/bin/sh


# If we're not running the postgres CI test, just return
[ "$CI" = "postgres" ] || return 0


echo "NOTICE: Creating DNS test data using pdnsutil..."
pdnsutil create-zone example.com ns.example.com
pdnsutil add-record example.com powerdns TXT WORKING
pdnsutil check-zone example.com
pdns_control rediscover
#pdns_control rediscover
echo "NOTICE: Created DNS test data"

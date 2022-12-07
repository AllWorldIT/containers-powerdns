#!/bin/sh


# If we're not running the mysql CI test, just return
[ "$CI" = "mysql" ] || return 0


# Check if we need to initialize the database
if [ -n "$MYSQL_DATABASE" ]; then
  export POWERDNS_INIT_MYSQL=yes
fi

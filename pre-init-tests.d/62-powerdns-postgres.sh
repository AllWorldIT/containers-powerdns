#!/bin/sh


# If we're not running the postgres CI test, just return
[ "$CI" = "postgres" ] || return 0


# Check if we need to initialize the database
if [ -n "$POSTGRES_DATABASE" ]; then
  export POWERDNS_INIT_POSTGRES=yes
fi

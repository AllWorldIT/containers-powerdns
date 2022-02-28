# Introduction

This is a PowerDNS container.

See the [Alpine Base Image](https://gitlab.iitsp.com/allworldit/docker/alpine) project for additional configuration.


# PowerDNS

The following directories can be mapped in:


## Directory: /etc/pdns/conf.d

PowerDNS configuration directory.

## Ports: 53/UDP+TCP, 8081

Exposes DNS ports 53 and webserver port 8081.


## POWERDNS_SERVER_ID

Required. Set the PowerDNS server ID that is returned on a EDNS NSID query.


## POWERDNS_WEBSERVER_ALLOW_FROM

Enable and allow access to the webui.

Examples of configuration: 192.168.0.0/24,fec0::/64

Port 8081 will be exposed.


## POWERDNS_WEBSERVER_PASSWORD

If the password is not set, it is automatically generated and output to logs.

This is used as the username and password to satisfy the authentication request.


## API_KEY

If the API key is not set, it is automatically generated and output to logs.


# PostgreSQL Backend


## POSTGRES_HOST

Database server hostname.


## POSTGRES_DATABASE

Database to connect to.


## POSTGRES_USER

Username to use to connect with.


## POSTGRES_USER_PASSWORD

User password to use when connecting to the database.


# MySQL Backend


## MYSQL_HOST

MySQL server hostname.


## MYSQL_DATABASE

Database to connect to.


## MYSQL_USER

Username to use to connect with.


## MYSQL_PASSWORD

User password to use when connecting to the database.



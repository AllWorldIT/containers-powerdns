[![pipeline status](https://gitlab.conarx.tech/containers/powerdns/badges/main/pipeline.svg)](https://gitlab.conarx.tech/containers/powerdns/-/commits/main)

# Container Information

[Container Source](https://gitlab.conarx.tech/containers/powerdns) - [GitHub Mirror](https://github.com/AllWorldIT/containers-powerdns)

This is the Conarx Containers PowerDNS image, it provides the PowerDNS authorative DNS server with support for both MySQL and
PostgreSQL backends.

Features:

- Bind-formatted zone files
- MySQL backend support
- PostgreSQL backend support
- Lua support

Dynamic modules built:

- bind
- geoip
- gmysql
- godbc
- gpgsql
- gsqlite3
- ldap
- lmdb
- lua2
- pipe
- remote


# Mirrors

|  Provider  |  Repository                              |
|------------|------------------------------------------|
| DockerHub  | allworldit/powerdns                      |
| Conarx     | registry.conarx.tech/containers/powerdns |



# Conarx Containers

All our Docker images are part of our Conarx Containers product line. Images are generally based on Alpine Linux and track the
Alpine Linux major and minor version in the format of `vXX.YY`.

Images built from source track both the Alpine Linux major and minor versions in addition to the main software component being
built in the format of `vXX.YY-AA.BB`, where `AA.BB` is the main software component version.

Our images are built using our Flexible Docker Containers framework which includes the below features...

- Flexible container initialization and startup
- Integrated unit testing
- Advanced multi-service health checks
- Native IPv6 support for all containers
- Debugging options



# Community Support

Please use the project [Issue Tracker](https://gitlab.conarx.tech/containers/powerdns/-/issues).



# Commercial Support

Commercial support for all our Docker images is available from [Conarx](https://conarx.tech).

We also provide consulting services to create and maintain Docker images to meet your exact needs.



# Environment Variables

Additional environment variables are available from...
* [Conarx Containers Alpine image](https://gitlab.conarx.tech/containers/alpine)


## POWERDNS_SERVER_ID

Required. Set the PowerDNS server ID that is returned on a EDNS NSID query.


## POWERDNS_WEBSERVER_ALLOW_FROM

Enable and allow access to the webui.

Examples of configuration: 192.168.0.0/24,fec0::/64

This option will enable the PowerDNS webserver and enable PowerDNS to listen on port 8081.


## POWERDNS_WEBSERVER_PASSWORD

If the password is not set, it is automatically generated and output to logs.

This is used as the username and password to satisfy the authentication request.


## POWERDNS_API_KEY

If the API key is not set, it is automatically generated and output to logs.

This option relies on the `POWERDNS_WEBSERVER_ALLOW_FROM` environment variable being set to enable the webserver which provides the
API.


## POWERDNS_DEFAULT_SOA_CONTENT

This should always be set, the PowerDNS Admin default is `a.misconfigured.dns.server.invalid hostmaster.@ 0 10800 3600 604800 3600`.

When setting this value the first field should be the administrators email address with the `@` replaced with a `.`.


## POWERDNS_EXPAND_ALIAS

Enable expanding of aliases, this option must be set to a DNS resolver to use to do this. eg. '172.16.0.1'


## POWERDNS_HEALTHECK_QUERY

Query to use to check that PowerDNS is responsivle. Defaults to `id.server CHAOS TXT`.

One could use something like this to check a specific domain `example.com A`.



# PostgreSQL Backend Environment Variables


## POSTGRES_HOST

Database server hostname.


## POSTGRES_DATABASE

Database to connect to.


## POSTGRES_USER

Username to use to connect with.


## POSTGRES_USER_PASSWORD

User password to use when connecting to the database.



# MySQL Backend Environment Variables


## MYSQL_HOST

MySQL server hostname.


## MYSQL_DATABASE

Database to connect to.


## MYSQL_USER

Username to use to connect with.


## MYSQL_PASSWORD

User password to use when connecting to the database.



# Remote Backend Environment Variables


## POWERDNS_REMOTE_CONNECTION_STRING

Set up a remote backend connection. See https://doc.powerdns.com/authoritative/backends/remote.html for more information.



# Configuration


## /etc/pdns/conf.d

The PowerDNS configuration directory supports configuration files that are bind mounted in from the host system.


## /etc/powerdns/conf.d/10-server-id.conf

PowerDNS server ID configuration file.


## /etc/powerdns/conf.d/40-defaults.conf

PowerDNS server defaults configuration file.


## /etc/powerdns/conf.d/42-soa-default.conf

PowerDNS server configuration for SOA defaults.


## /etc/powerdns/conf.d/50-backend.conf

PowerDNS server backend configuration file.


## /etc/powerdns/conf.d/52-webserver.conf

PowerDNS server configuration file for webserver and API.


## /etc/powerdns/conf.d/60-lua-records.conf

PowerDNS server configuration for LUA records.



# Exposed Ports

PowerDNS ports 53 (UDP/TCP) and webserver port 8081 are exposed.



# Configuration Examples

Various reference examples are included...

- [PowerDNS with MariaDB](contrib/mariadb/docker-compose.yml)
- [PowerDNS with PostgreSQL](contrib/postgresql/docker-compose.yml)

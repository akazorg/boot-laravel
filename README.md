```
     _                 _
    | |               | |
    | |__   ___   ___ | |_
    | '_ \ / _ \ / _ \| __|
    | |_) | (_) | (_) | |_
    |_.__/ \___/ \___/ \__|
```
#### Fast and Reliable Server Manager for Laravel, Nginx and MySQL

Boot is a fast way of managing web servers based with Laravel, Nginx and MySQL. It simplifies adding new hosts, by automatically set all the necessary configurations.

Designed for development and production servers. Tested on Ubuntu 16+.


#### Features
- Craft a new Laravel (or other) site, fully configured with SSL, Nginx and MySQL
- Nginx Tasks: add, remove, enable, disable and list hosts
- Create/Drop Databases, users and grant permissions
- Config file per project

When adding a host, a config file is generated at `./hosts/<host_name>.cnf` containing all project information.
Attention, the Password of user database will be auto generated and stored here.


#### Default Settings (located at `boot.env` file)
- DB_USER=boot
- DB_PASS=secret
- HOST_NAME=localhost
- HOST_IP=127.0.0.1
- HOST_TYPE=laravel
- HOST_PATH="/var/www"


#### Usage
```
$ ./boot [-hlredR] [-a type] <domain>

Options:
    -h      : help
    -l      : list hosts
    -r      : reload nginx
    -e      : enable a host
    -d      : disable a host
    -R      : remove a host (can really damage your system)
    -a type : create a new host type: site, laravel (default)
```


#### Examples
```bash
$./boot -e domain.dev      # Enables domain.dev
$./boot -R domain.dev      # Removes domain.dev
$./boot -a abc.dev         # Creates laravel site at /var/www/abc.dev
$./boot -a site xyz.api    # Creates php site at /var/www/xyz.api
```


#### Author
Boot is developed by [Bruno Torrinha](http://www.torrinha.com).

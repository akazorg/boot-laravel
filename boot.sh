#!/bin/bash

# Boot - Fast & reliable server manager for Nginx, MySql, and Laravel.
#
# Description:
#   Automates nginx tasks: list hosts, add, remove, enable and disable.
#   Create Mysql databases, users and grant permissions.
#   Craft new laravel projects with .env file ready to go.
#
# Usage: boot [-hlredR] [-a type] <domain>
#
#     Options:
#     -h      : this help
#     -l      : list hosts
#     -r      : reload nginx
#     -e      : enable a host
#     -d      : disable a host
#     -R      : remove a host (can really damage your system)
#     -a type : create a new host type: site, laravel (default)
#
# Examples:
#     boot -e domain.dev    : enables domain.dev
#     boot -R domain.dev    : removes domain.dev
#     boot -a abc.dev       : creates laravel site at /var/www/abc.dev
#     boot -a site xyz.api  : creates php site at /var/www/xyz.api
#
# Author: Bruno Torrinha <http://www.torrinha.com>
#
# Inspired on
# - https://github.com/pyghassen/nginx_modsite
# - Laravel Homestead provisioning scripts

# tab width
tabs 4
# clear

##########
# Defaults
#######################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# DB_NAME=
# DB_USER="boot"  # Will append the db name: "database_boot"
# HOST_PATH="/var/www"
# HOST_TYPE="laravel"
HOST_NAME="$2"
NGINX_CONF_FILE="$(awk -F= -v RS=' ' '/conf-path/ {print $2}' <<< $(nginx -V 2>&1))"
NGINX_CONF_DIR="${NGINX_CONF_FILE%/*}"
NGINX_SITES_AVAILABLE="$NGINX_CONF_DIR/sites-available"
NGINX_SITES_ENABLED="$NGINX_CONF_DIR/sites-enabled"
NGINX_RELOAD_ON_CHANGE=true

# Include common scripts
. $DIR/inc/messages.sh

# Load variables
while read line; do export "$line"; echo "$line";
done < $DIR/boot.env


###########
# Functions
#######################################
_err () {
    _error "$1"
    usage "$2"
}

check_root_user() {
    if [ "$(whoami)" != 'root' ]; then
        _err "Use sudo. You need permission to run $0."
    fi
}

load_host() {
    # Sanitize DB name
    name=${HOST_NAME//_/}               # remove underscores
    name=${name//./}                    # remove dots
    name=${name//[^a-zA-Z0-9_]/}        # remove non alphanumeric or underscores
    name=`echo -n $name | tr A-Z a-z`   # make lowercase

    DB_NAME=$name                   # DB Name Sanitized
    DB_USER="$name"_"$DB_USER"      # DB Username
    DB_USER_PASS=`pwgen -s 12 1`    # DB Password
}

confirm_host_settings() {
    echo "Confirm Settings..."
    echo ""
    echo "➜ Nginx"
    echo "+----------------------------------------"
    echo "| Host : $HOST_NAME"
    echo "| Path : $HOST_PATH/$HOST_NAME"
    echo "+----------------------------------------"
    echo " "
    echo "➜ MySQL DB"
    echo "+----------------------------------------"
    echo "| Name : $DB_NAME"
    echo "| User : $DB_USER"
    echo "| Pass : $DB_USER_PASS"
    echo "+----------------------------------------"
    echo ""
    read -p "➜ Proceed with create? (Y/n): " confirm
    if [[ "$confirm" = "n" || "$confirm" = "N" ]]; then
        _alert "Configuration aborted"
        exit 0
    fi
}

save_host_config() {
cat > $DIR/hosts/$HOST_NAME.cnf << EOF
date_added=$(date)
host_name=$HOST_NAME
host_path=$HOST_PATH/$HOST_NAME
database_name=$DB_NAME
database_user=$DB_USER
database_pass=$DB_USER_PASS
EOF
    echo -e "\nProject details saved at $DIR/hosts/$HOST_NAME.cnf\n"
    echo -e "Build something great: http://$HOST_NAME\n"
}

#######
# Nginx
#######################################
ngx_sites() {
    case "$1" in
        available) dir="$NGINX_SITES_AVAILABLE";;
        enabled) dir="$NGINX_SITES_ENABLED";;
    esac

    for file in $dir/*; do
        echo -e "\t${file#*$dir/}"
    done
}

ngx_reload() {
    if [ "$NGINX_RELOAD_ON_CHANGE" = true ]; then
        ngx_reload_now
    fi
}

ngx_reload_now() {
    # invoke-rc.d php7.0-fpm restart
    invoke-rc.d nginx reload
    _success "Nginx reloaded"
}

ngx_list() {
    _success "Available hosts"
    ngx_sites "available"
    _success "Enabled hosts"
    ngx_sites "enabled"
}

ngx_enable_host() {
    [[ ! "$HOST_NAME" ]] && _err "Domain was not submitted."

    [[ ! -e "$NGINX_SITES_AVAILABLE/$HOST_NAME" ]] &&
        _err "$HOST_NAME site does not appear to exist."

    [[ -e "$NGINX_SITES_ENABLED/$HOST_NAME" ]] &&
        _err "$HOST_NAME site appears to already be enabled"

    ln -sf "$NGINX_SITES_AVAILABLE/$HOST_NAME" "$NGINX_SITES_ENABLED/$HOST_NAME"
    _success "Site $HOST_NAME enabled"
    ngx_reload
}

ngx_disable_host() {
    [[ ! "$HOST_NAME" ]] && _err "Domain name not submitted."

    [[ ! -e "$NGINX_SITES_AVAILABLE/$HOST_NAME" ]] &&
        _err "$HOST_NAME site does not appear to be \'available\'. - Not Removing"

    [[ ! -e "$NGINX_SITES_ENABLED/$HOST_NAME" ]] &&
        _err "$HOST_NAME site already disabled." 0

    rm -rf "$NGINX_SITES_ENABLED/$HOST_NAME"

    _success "Site $HOST_NAME disabled"
    ngx_reload
}

ngx_add_host() {
    sudo -v

    #####################
    # Prepare Variables #
    #####################

    # Load host settings
    case "$1" in
        site|laravel)
            HOST_TYPE="$1"
            HOST_NAME="$2";;
    esac

    load_host

    # Check if already installed
    [[ -e "$NGINX_SITES_AVAILABLE/$HOST_NAME" ]] &&
        _err "$HOST_NAME already exists"

    confirm_host_settings

    # Create Mysql database, User and assign permission
    bash $DIR/scripts/create-mysql.sh "$DB_NAME" "$DB_USER" "$DB_USER_PASS"

    # Create host
    case "$HOST_TYPE" in
        site) bash $DIR/scripts/create-site.sh "$HOST_NAME" "$HOST_PATH" "$NGINX_CONF_DIR";;
        laravel) bash $DIR/scripts/create-laravel.sh "$HOST_NAME" "$HOST_PATH" "$NGINX_CONF_DIR";;
    esac

    # Create /etc/hosts
    bash $DIR/scripts/hosts-etc.sh "add" "$HOST_NAME" "$HOST_IP"

    ngx_reload
    save_host_config

    exit 0
}

ngx_remove_host() {
    sudo -v

    [[ ! "$HOST_NAME" ]] && _err "Domain name not submitted."

    [[ ! -e "$NGINX_SITES_AVAILABLE/$HOST_NAME" ]] &&
        _err "$HOST_NAME site is not configured."

    load_host

    # Remove host
    bash $DIR/scripts/remove-host.sh "$HOST_PATH" "$HOST_NAME" "$NGINX_CONF_DIR"

    # Remove database
    bash $DIR/scripts/remove-mysql.sh "$DB_NAME" "$DB_USER"

    # Update hosts
    bash $DIR/scripts/hosts-etc.sh "remove" "$HOST_NAME" "$HOST_IP"

    ngx_reload
    _success "Host removed"
    exit 0
}


############
# Help About
#######################################

header() {
cat <<"HEADER"
 _                 _
| |               | |
| |__   ___   ___ | |_
| '_ \ / _ \ / _ \| __|
| |_) | (_) | (_) | |_
|_.__/ \___/ \___/ \__|

Fast and reliable web server manager.
Automates nginx tasks: list hosts, add, remove, enable and disable.
Creates Mysql databases, users and grant permissions.
Can bootstrap new laravel projects.

Nginx / Mysql / Laravel

@ 2017 Bruno Torrinha <http://www.github.com/akazorg/laravel-boot>

HEADER
}


usage() {
    [[ "$1" = "1" ]] && header;

cat <<"USAGE"
Usage: boot [-hlredR] [-a type] <domain>

    Options:
    -h      : this help
    -l      : list hosts
    -r      : reload nginx
    -e      : enable host
    -d      : disable host
    -R      : remove host (can really damage your system)
    -a type : create host type: site, laravel (default)

Examples:
    boot -e domain.dev    : enables domain.dev
    boot -R domain.dev    : removes domain.dev
    boot -a abc.dev       : creates laravel site at /var/www/abc.dev
    boot -a site xyz.api  : creates php site at /var/www/xyz.api

USAGE
    exit 1;
}


#############
# Start Block
#######################################

check_root_user

case "$1" in
    -h|'') usage 1;;
    -r)    ngx_reload_now;;
    -l)    ngx_list;;
    -e)    ngx_enable_host;;
    -d)    ngx_disable_host;;
    -R)    ngx_remove_host;;
    -a)    ngx_add_host $2 $3 $4;;
    *)     _err "No options selected" 1;;
esac

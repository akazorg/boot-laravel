#!/bin/bash

##
# Remove a Host
##

HOST_PATH=$1
HOST_NAME=$2
NGINX_CONF_DIR=$3
HOST_FULL_PATH="$1/$2"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include common scripts
. $DIR/../inc/messages.sh

#########
# Start #
#########
if [[ ! "$HOST_FULL_PATH" ]]; then
    _error "Path not found. $HOST_FULL_PATH"
    exit 0;
fi


_alert "CAUTION - REMOVING FILES"
read -p "➜ Remove host from $HOST_FULL_PATH? (y/N): " delete
if [[ "$delete" = "y" || "$delete" = "Y" ]]; then
    # Remove files
    rm -rf "$HOST_FULL_PATH"
    _success "Files deleted"
fi

##
# Remove Certificates
##
rm -f "$NGINX_CONF_DIR/ssl/$HOST_NAME.crt"
rm -f "$NGINX_CONF_DIR/ssl/$HOST_NAME.csr"
rm -f "$NGINX_CONF_DIR/ssl/$HOST_NAME.key"


##
# Update Nginx
##
rm -f "$NGINX_CONF_DIR/sites-enabled/$HOST_NAME"
rm -f "$NGINX_CONF_DIR/sites-available/$HOST_NAME"
_success "Nginx removed"

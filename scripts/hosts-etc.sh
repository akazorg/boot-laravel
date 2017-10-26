#!/bin/bash

# This script provides Add/Remove hosts from /etc/hosts file
#
# Usage: [add|remove] <hostname> <ip>

ACTION=$1
HOST=$2
IP=${3:-127.0.0.1}

# Include common scripts
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/../inc/messages.sh

#############
# Functions #
#############

add_host_etc()
{
    grep -q -F "${IP} ${1}" /etc/hosts || echo "${IP} ${1}" >> /etc/hosts
    _success "/etc/hosts updated"
}

remove_host_etc()
{
    sed -ie "\|^$IP $1\$|d" /etc/hosts
    _success "/etc/hosts updated"
}


###############
# Start Block #
###############

case "$1" in
    add)    add_host_etc $2;;
    remove) remove_host_etc $2;;
esac

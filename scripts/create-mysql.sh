#!/bin/bash

##
# Create MySQL Database, User, and Grant Permission
##

export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0

DB_HOST='localhost'
DB_ADD_DEL=$1
DB_NAME=$2
DB_USERNAME=$3
DB_PASSWORD=$4


BIN_MYSQL=$(which mysql)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include common scripts
. $DIR/../inc/messages.sh

#############
# Functions #
#############
setup_db()
{
    SQL1="CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci;"
    SQL2="GRANT ALL ON ${DB_NAME}.* TO '${DB_USERNAME}'@'$DB_HOST' IDENTIFIED BY '${DB_PASSWORD}';"
    SQL3="FLUSH PRIVILEGES;"
    SQL=""

    if [ "$DB_ADD_DEL" = true ]; then
        SQL="${SQL1}"
    fi

    SQL="${SQL}${SQL2}${SQL3}"

    if [ -f ~/.my.cnf ]; then
        $BIN_MYSQL -e "$SQL"
    else
        echo "➜ Enter MySQL root password: "
        $BIN_MYSQL -uroot -p -e "$SQL"
    fi

    _success "MySQL database"
}

#########
# Start #
#########
setup_db

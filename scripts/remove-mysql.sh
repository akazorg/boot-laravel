#!/bin/bash

BIN_MYSQL=$(which mysql)

DB_HOST='localhost'
DB_ADD_DEL=$1
DB_NAME=$2
DB_USERNAME=$3

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include common scripts
. $DIR/../inc/messages.sh

#############
# Functions #
#############
remove_db()
{
    SQL1="DROP DATABASE ${DB_NAME};"
    SQL2="DROP USER '${DB_USERNAME}'@'${DB_HOST}';"
    SQL=""

    if [ "$DB_ADD_DEL" = true ]; then
        SQL="${SQL1}"
    fi

    SQL="${SQL}${SQL2}"

    if [ -f ~/.my.cnf ]; then
        $BIN_MYSQL -e "$SQL"
    else
        echo "➜ Enter MySQL root password: "
        $BIN_MYSQL -uroot -p -e "$SQL"
    fi

    _success "MySQL removed"
}

#########
# Start #
#########
_alert "CAUTION - REMOVING DATABASE";
read -p "➜ Remove database $DB_NAME? (y/N) " delete
if [[ "$delete" = "y" || "$delete" = "Y" ]]; then
    remove_db
fi

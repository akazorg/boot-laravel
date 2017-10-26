#!/bin/bash

BIN_MYSQL=$(which mysql)

DB_HOST='localhost'
DB_NAME=$1
DB_USERNAME=$2

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include common scripts
. $DIR/../inc/messages.sh

#############
# Functions #
#############
remove_db()
{
    SQL2="DROP USER '${DB_USERNAME}'@'${DB_HOST}';"
    SQL3="DROP DATABASE ${DB_NAME};"
    SQL="${SQL2}${SQL3}"

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

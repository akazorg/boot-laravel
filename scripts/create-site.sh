#!/bin/bash

##
# Create Generic Site
##

HOST_NAME=$1
HOST_PATH=$2
NGINX_CONF_DIR=$3
HOST_HTTP=$4
HOST_HTTPS=$5
HOST_PATH_FULL="$HOST_PATH/$HOST_NAME";

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include common scripts
. $DIR/../inc/messages.sh

#############
# Functions #
#############
provision()
{
    # Create site folder
    mkdir -p "$HOST_PATH_FULL/storage"
    mkdir -p "$HOST_PATH_FULL/public"

    # Create SSL
    sudo -u www-data mkdir "$NGINX_CONF_DIR/ssl" 2>/dev/null
    PATH_SSL="$NGINX_CONF_DIR/ssl"
    PATH_KEY="${PATH_SSL}/${HOST_NAME}.key"
    PATH_CSR="${PATH_SSL}/${HOST_NAME}.csr"
    PATH_CRT="${PATH_SSL}/${HOST_NAME}.crt"
}

setup_nginx()
{
    if [ ! -f $PATH_KEY ] || [ ! -f $PATH_CSR ] || [ ! -f $PATH_CRT ]
    then
        openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
        openssl req -new -key "$PATH_KEY" -out "$PATH_CSR" -subj "/CN=$HOST_NAME/O=$HOST_NAME/C=UK" 2>/dev/null
        openssl x509 -req -days 365 -in "$PATH_CSR" -signkey "$PATH_KEY" -out "$PATH_CRT" 2>/dev/null
    fi

    block="server {
        listen ${HOST_HTTP:-80};
        listen ${HOST_HTTPS:-443} ssl http2;
        server_name $HOST_NAME;
        root \"$HOST_PATH_FULL/public\";

        index index.php index.html index.htm;

        charset utf-8;

        error_page 404 /404.html;

        location / {
            try_files \$uri \$uri/ =404;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        access_log off;
        error_log  /var/log/nginx/$HOST_NAME-error.log error;

        sendfile off;

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }

        # location ~ /\.ht {
        #     deny all;
        # }

        ssl_certificate     $NGINX_CONF_DIR/ssl/$HOST_NAME.crt;
        ssl_certificate_key $NGINX_CONF_DIR/ssl/$HOST_NAME.key;
    }
    "

    echo "$block" > "$NGINX_CONF_DIR/sites-available/$HOST_NAME"
    ln -fs "$NGINX_CONF_DIR/sites-available/$HOST_NAME" "$NGINX_CONF_DIR/sites-enabled/$HOST_NAME"
    _success "Nginx configured"
}

install_site()
{
    echo "${HOST_NAME} homepage" > "$HOST_PATH_FULL/public/index.html"
}

create_env_file()
{
    ENV="$DIR/scripts/stubs/.env"

    cp "$ENV" $HOST_PATH_FULL/.env 2> /dev/null

    # Replace .env variables
    # sed -e 's/^APP_URL=.*/APP_URL=${APP_URL}/' -e 's/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/' -e 's/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/' -e 's/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}' > $HOST_PATH_FULL/.env

    # sed 's/^aaa=.*/aaa=xxx/'
}

grant_permissions()
{
    sudo chown -R www-data:www-data "$HOST_PATH_FULL"
    sudo chown -R www-data:www-data "$HOST_PATH_FULL/public"
    sudo chown -R www-data:www-data "$HOST_PATH_FULL/storage"
    sudo chmod -R ugo+w "$HOST_PATH_FULL/storage"
    sudo chmod -R 775 "$HOST_PATH_FULL/storage"
    _success "Permissions granted"
}


#########
# Start #
#########
provision
setup_nginx
install_site
create_env_file
grant_permissions

_success "Site installed"

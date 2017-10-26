#!/bin/bash

##
# Create Laravel Site
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
    mkdir -p "$HOST_PATH_FULL"

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

        index index.html index.htm index.php;

        charset utf-8;

        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        access_log off;
        error_log  /var/log/nginx/$HOST_NAME-error.log error;

        sendfile off;

        client_max_body_size 100m;

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 300;
        }

        location ~ /\.ht {
            deny all;
        }

        ssl_certificate     $NGINX_CONF_DIR/ssl/$HOST_NAME.crt;
        ssl_certificate_key $NGINX_CONF_DIR/ssl/$HOST_NAME.key;
    }
    "

    echo "$block" > "$NGINX_CONF_DIR/sites-available/$HOST_NAME"
    ln -fs "$NGINX_CONF_DIR/sites-available/$HOST_NAME" "$NGINX_CONF_DIR/sites-enabled/$HOST_NAME"
    _success "Nginx configured"
}

install_laravel()
{
    echo -e "Installing latest version of Laravel...\n"
    sudo composer create-project laravel/laravel $HOST_PATH_FULL
}

grant_permissions()
{
    sudo chown -R www-data:www-data "$HOST_PATH_FULL"
    sudo chown -R www-data:www-data "$HOST_PATH_FULL/public"
    sudo chown -R www-data:www-data "$HOST_PATH_FULL/storage"
    sudo chmod -R 775 "$HOST_PATH_FULL/storage"
    _success "Permissions granted"
}


#########
# Start #
#########
provision
setup_nginx
install_laravel
grant_permissions

_success "Laravel installed"

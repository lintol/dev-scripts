#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh


echo
echo
echo "INSTALLING CAPSTONE"
echo

if [ ! -d ./capstone ]
then
    git clone https://github.com/lintol/capstone
fi

if [ ! -e ./capstone/infrastructure/.git ]
then
    rm -rf capstone/infrastructure
    cd capstone
    git clone https://gitlab.com/lintol/buckram infrastructure
    ./infrastructure/setup_local.sh
    sed -i 's/80:80/8082:80/' docker-compose.yml
    cd ..
fi

(cd capstone; git submodule init; git submodule update)

(cd capstone; docker-compose up) &
sleep 5
(cd capstone; docker-compose stop)
export NETWORK_CAPSTONE_ROOT=$(docker network inspect capstone_default | grep Subnet | sed 's/^\s*"Subnet": "\(.*\)0.0.*/\10.1/')

if [ ! -e ./capstone/.env ]
then
    echo "
APP_NAME=Lintol
APP_KEY=
APP_ENV=dev
APP_DEBUG=true
APP_LOG_LEVEL=debug
APP_URL=https://$LINTOL_SITE

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=secret

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=

GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}

LINTOL_FRONTEND_URL=https://$LINTOL_SITE/
LINTOL_FRONTEND_PROXY=http://${NETWORK_CKAN_ROOT}:8081/
LINTOL_BLIND_INDEX_KEY=$LINTOL_BLIND_INDEX_KEY
LINTOL_CKAN_SERVERS=https://$CKAN_SITE
LINTOL_CAPSTONE_URL=ws://${NETWORK_CAPSTONE_ROOT}:8080/ws

CKAN_CLIENT_ID=
CKAN_CLIENT_SECRET=
CKAN_URL=https://$CKAN_SITE
KEY_PATH=/var/www/app/secrets
    " > capstone/.env
fi


sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update -y

if [ ! -e ./capstone/composer ]
then
    cd capstone
    sudo apt-get install -y php7.1-curl php7.1 php7.1-dom php7.1-mbstring
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    sudo php composer-setup.php
    rm -f composer-setup.php
    mv composer.phar composer
    cd ..
fi
cd capstone; mkdir secrets; cd ..
cd capstone; ./composer install; cd ..

(cd capstone; docker-compose run --entrypoint php artisan_worker /var/www/app/artisan --force migrate:refresh)
(cd capstone; docker-compose run --entrypoint php artisan_worker /var/www/app/artisan --force db:seed)
(cd capstone; docker-compose run --entrypoint php artisan_worker /var/www/app/artisan passport:install)
(cd capstone; docker-compose run --entrypoint php artisan_worker /var/www/app/artisan key:generate)
(cd capstone; docker-compose run --user root --entrypoint touch artisan_worker /var/www/app/storage/logs/laravel.log)
(cd capstone; docker-compose run --user root --entrypoint /bin/sh artisan_worker -c 'mkdir /var/www/app/secrets; cp /var/www/app/storage/oauth-* /var/www/app/secrets')
(cd capstone; docker-compose run --user root --entrypoint chown artisan_worker -R www-data /var/www/app/bootstrap/cache /var/www/app/storage)
(cd capstone; docker-compose up) &

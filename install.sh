#!/bin/bash

source settings.sh
source settings-calculated.sh

## 16.04

#source ./install-base.sh

#newgrp docker
#
source ./install-crossbar.sh

docker-compose -f docker-compose.crossbar.yml up &

sleep 2

source ./install-ckan.sh

docker-compose -f docker-compose.ckan.yml up &

sleep 10

docker exec -i ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini remove $CKAN_USER
echo "y
$CKAN_EMAIL
password
password
" | docker exec -i ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add $CKAN_USER | grep apikey | sed "s/.*u'\(.*\)',/\1/"

source ./install-nginx.sh

source ./install-capstone.sh

source ./install-frontend.sh

source ./install-doorstep.sh


CKAN_INI=./ckan-config/production.ini
APIKEY=$(docker exec -i ckan /usr/local/bin/ckan-paster --plugin=ckan user -c /etc/ckan/production.ini $CKAN_USER | grep apikey | sed 's/.*apikey=\(\S*\).*/\1/')
echo 'apikey' $APIKEY
curl -H "Authorization:${APIKEY}" 'http://localhost:5000/ckan-admin/oauth2provider-clients/new' --data "name=${LINTOL_SITE}&url=${LINTOL_SITE}&redirect_uri=${LINTOL_SITE}%2Flogin%2Fckan%2Fcallback&client_type=0&username=johndoe&save=" > /dev/null
CLIENT_ID=$(curl -s -H "Authorization:${APIKEY}" 'http://localhost:5000/ckan-admin/oauth2provider-clients' | grep -b1 ${LINTOL_SITE} | tail -n 1 | sed 's/.*<td>\(.*\)<\/td>/\1/g')
CLIENT_SECRET=$(curl -s -H "Authorization:${APIKEY}" 'http://localhost:5000/ckan-admin/oauth2provider-clients' | grep -b2 ${LINTOL_SITE} | tail -n 1 | sed 's/.*<td>\(.*\)<\/td>/\1/g')
ACCESS_TOKEN=$(docker exec -i capstone_artisan_worker_1 php /var/www/app/artisan ltl:ckan-token ${CKAN_SITE} https://${CKAN_SITE} ${CLIENT_ID} ${CLIENT_SECRET})
rm -f access_token
echo "ckanext.validation.lintol_token = $ACCESS_TOKEN" > access_token
sed -i -e '/ckan.validation.lintol_token =/d' -e '/ckanext.validation.run_on_update_async/ r access_token' $CKAN_INI
rm -f access_token

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

source ./link-ckan-lintol.sh

#!/bin/bash

source ./settings.sh

CKAN_PORT=5000 CKAN_SITE_URL=https://${CKAN_SITE} ROUTER=crossbar docker-compose -f docker-compose.yml up &

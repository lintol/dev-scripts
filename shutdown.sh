#!/bin/sh

docker-compose stop
docker-compose -f docker-compose.ckan.yml stop &
docker-compose -f docker-compose.crossbar.yml stop &
(cd capstone; docker-compose stop) &
docker-compose -f docker-compose.frontend.yml stop &
docker-compose -f docker-compose.doorstep.yml stop &

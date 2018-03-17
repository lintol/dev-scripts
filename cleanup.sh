#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh

sudo umount ckan-config ckan-home
docker ps -a -q | xargs docker rm
docker volume ls -q | xargs docker volume rm
docker network ls -q | xargs docker network rm
rm -rf ckan-config ckan-home

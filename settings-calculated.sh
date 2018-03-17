#!/bin/bash

source ./settings.sh
export NETWORK_CKAN_ROOT=$(docker network inspect $(basename $(pwd))_default | grep Subnet | sed 's/^\s*"Subnet": "\(.*\)0.0.*/\10.1/')
export NETWORK_CAPSTONE_ROOT=$(docker network inspect capstone_default | grep Subnet | sed 's/^\s*"Subnet": "\(.*\)0.0.*/\10.1/')

export CKAN_SITE_URL=https://${CKAN_SITE}

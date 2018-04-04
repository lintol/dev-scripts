#!/bin/sh

(cd ck; ./pre-dockerfile-setup.sh)

docker-compose -f docker-compose.live.yml up

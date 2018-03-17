#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh

echo
echo
echo "INSTALLING DOORSTEP"
echo

if [ ! -d ./doorstep ]
then
    git clone https://github.com/lintol/doorstep
fi

(cd doorstep; echo "
python setup.py develop
" | docker run -u root -i -v $(pwd):/doorstep --entrypoint /bin/bash lintol/doorstep)

#tempsolution
sudo  rm -f /doorstep
sudo ln -s $(pwd)/doorstep /doorstep

docker-compose -f docker-compose.doorstep.yml up &
sleep 2
docker-compose -f docker-compose.doorstep.yml stop
export NETWORK_DOORSTEP_ROOT=$(docker network inspect $(basename $(pwd))_default | grep Subnet | sed 's/^\s*"Subnet": "\(.*\)0.0.*/\10.1/')
ROUTER=$NETWORK_DOORSTEP_ROOT docker-compose -f docker-compose.doorstep.yml up &

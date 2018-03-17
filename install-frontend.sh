#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh

echo
echo
echo "INSTALLING FRONTEND"
echo

if [ ! -d ./lintol-frontend ]
then
    git clone https://github.com/lintol/lintol-frontend
fi

which npm
if [ $? -eq 1 ]
then
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

(cd lintol-frontend; docker run -v $(pwd):/usr/src/app --entrypoint npm --workdir /usr/src/app node install)
docker-compose -f docker-compose.frontend.yml up &

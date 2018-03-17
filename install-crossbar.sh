#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh

echo
echo
echo "INSTALLING CROSSBAR"
echo

if [ ! -d ./crossbar-starter ]
then
    git clone https://github.com/crossbario/crossbar-starter
fi

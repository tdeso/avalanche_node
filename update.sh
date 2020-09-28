#!/bin/bash

################################################
# Simple Bash script to update an Avalanche Node
# ##############################################

echo '### Updating packages...'
sudo apt-get -y update

echo '### Updating the repository...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
git pull

echo '### Updating Avalanche node service...'
./scripts/build.sh
sudo systemctl restart avaxnode

echo 'Done !'
echo 'Type the following command to monitor the AVA node service:'
echo '    sudo systemctl status avaxnode'

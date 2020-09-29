#!/bin/bash

################################################
# Simple Bash script to update an Avalanche Node
# ##############################################

echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go

sudo systemctl stop avalanchenode
sudo systemctl stop avalanche
sudo systemctl stop avaxnode

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
echo 'sudo systemctl status avaxnode'

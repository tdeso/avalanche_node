#!/bin/bash

#########################################
# Bash script to update an Avalanche Node
#########################################

echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go

sudo systemctl stop avalanchenode
sudo systemctl disable avalanchenode

sudo systemctl stop avalanche
sudo systemctl disable avalanche

sudo systemctl stop avaxnode

sudo sed -i -e 's/avalanchenode/avaxnode/g' $HOME/avalanche-discord.py

echo '### Updating packages...'
sudo apt-get -y update

echo '### Fixing the databse...'
cd ~/.avalanchego
rm -rf db

echo '### Updating the repository...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
git pull

echo '### Updating Avalanche node service...'
./scripts/build.sh
sudo systemctl start avaxnode

echo '!!!!!!!!!!'
echo '!! DONE !!'
echo '!!!!!!!!!!'
echo 'Type the following command to monitor the Avalanche node service:'
echo 'sudo systemctl status avaxnode'

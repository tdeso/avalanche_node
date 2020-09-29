#!/bin/bash

#########################################
# Bash script to update an Avalanche Node
#########################################

echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go

sudo systemctl stop avalanche
sudo systemctl disable avalanche

echo '### Updating packages...'
sudo apt-get -y update

echo '### Fixing the databse...'
cd $HOME/.avalanchego
rm -rf db

echo '### Updating the repository...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
git pull

echo '### Updating Avalanche node service...'
./scripts/build.sh
cd
sudo rm -f /etc/systemd/system/avalanche.service

sudo bash -c 'cat <<EOF > /etc/.avalanchenodeconf
ARG1=--public-ip=
ARG2=--snow-quorum-size=14
ARG3=--snow-virtuous-commit-threshold=15
EOF'

sudo USER=$USER bash -c 'cat <<EOF > /etc/systemd/system/avalanche.service
[Unit]
Description=Avalanche node service
After=network.target

[Service]
User=$USER
Group=$USER

WorkingDirectory='$GOPATH'/src/github.com/ava-labs/avalanchego
EnvironmentFile=/etc/.avalanchenodeconf
ExecStart='$GOPATH'/src/github.com/ava-labs/avalanchego/build/avalanchego $ARG2 $ARG3

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF'

echo '### Launching Avalanche node...'
sudo systemctl enable avalanche
sudo systemctl start avalanche

echo '!!!!!!!!!!'
echo '!! DONE !!'
echo '!!!!!!!!!!'
echo 'Type the following command to monitor the Avalanche node service:'
echo 'sudo systemctl status avalanche'

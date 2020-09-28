#!/bin/bash

#######################################
# Bash script to install dependencies in Ubuntu 18.04.x LTS
# for https://www.avalabs.org/ Nodes
# ######################################
    
echo '    /\ \    / /\   | |        /\   | \ | |/ ____| |  | |  ____|
echo '   /  \ \  / /  \  | |       /  \  |  \| | |    | |__| | |__   
echo '  / /\ \ \/ / /\ \ | |      / /\ \ | . ` | |    |  __  |  __|  
echo ' / ____ \  / ____ \| |____ / ____ \| |\  | |____| |  | | |____ 
echo '/_/    \_\/_/    \_\______/_/    \_\_| \_|\_____|_|  |_|______|


echo '### Checking if systemd is supported...'
if systemctl show-environment &> /dev/null ; then
SYSTEMD_SUPPORTED=1
echo 'systemd is available, using it'
else
echo 'systemd is not available on this machine, will use supervisord instead'
fi

echo '### Updating packages...'
sudo apt-get update -y

echo '### Installing Go...'
wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go
go version


echo '### Installing Nodejs...'
sudo apt-get update -y
sudo apt-get -y install curl dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get -y install nodejs
sudo apt-get -y install build-essential
sudo apt-get -y install gcc g++ make


echo '### Cloning avalanchego directory...'
cd $HOME
go get -v -d github.com/ava-labs/avalanchego/...

echo '### Building avalanchego binary...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
./scripts/build.sh

echo '### Creating Avalanche node service...'
sudo USER=$USER bash -c 'cat <<EOF > /etc/systemd/system/avaxnode.service
[Unit]
Description=Avalanche node service
After=network.target

[Service]
User=$USER
Group=$USER

WorkingDirectory='$GOPATH'/src/github.com/ava-labs/avalanchego
ExecStart='$GOPATH'/src/github.com/ava-labs/avalanchego/build/avalanchego

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
sudo systemctl enable avaxnode
sudo systemctl start avaxnode
echo 'Type the following command to monitor the AVAX node service:'
echo '    sudo systemctl status avaxnode'

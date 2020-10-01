#!/bin/bash
    
echo '    /\ \    / /\   | |        /\   | \ | |/ ____| |  | |  ____|
echo '   /  \ \  / /  \  | |       /  \  |  \| | |    | |__| | |__   
echo '  / /\ \ \/ / /\ \ | |      / /\ \ | . ` | |    |  __  |  __|  
echo ' / ____ \  / ____ \| |____ / ____ \| |\  | |____| |  | | |____ 
echo '/_/    \_\/_/    \_\______/_/    \_\_| \_|\_____|_|  |_|______|


echo '### Updating packages...'
sudo apt-get update -y

echo '### Importing scripts...'
cd $HOME && mkdir bin
git clone https://github.com/tdeso/avalanche_node.git
mv $HOME/avalanche_node/*.sh $HOME/bin/ && chmod +x $HOME/bin/*.sh && rm -rf avalanche_node

echo '### Installing Go...'
wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go
go version

echo '### Cloning avalanchego directory...'
cd $HOME
go get -v -d github.com/ava-labs/avalanchego/...

echo '### Building avalanchego binary...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
./scripts/build.sh

echo '### Creating Avalanche node service...'
#sudo read -p "Enter your VPS public IP: "  PUBLIC_IP 
sudo bash -c 'cat <<EOF > /etc/.avalanche.conf
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
EnvironmentFile=/etc/.avalanche.conf
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


echo '### Creating Avalanche auto-update service'
sudo USER=$USER bash -c 'cat <<EOF > /etc/systemd/system/avaxmonitoring.service
[Unit]
Description=Avalanche update monitoring service
After=network.target

[Service]
User=$USER
Group=$USER

WorkingDirectory='$HOME'/bin
ExecStart='$HOME'/bin/monitoring.sh

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF'

echo '### Launching Avalanche auto-update service...'
sudo systemctl enable avaxmonitoring
sudo systemctl start avaxmonitoring

echo '### Launching Avalanche node...'
sudo systemctl enable avalanche
sudo systemctl start avalanche

echo 'Node launched'
echo 'Type the following command to monitor the Avalanche node service:'
echo '    sudo systemctl status avalanche'
echo 'To change the launch arguments, edit the /etc/.avalanche.conf file'

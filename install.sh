#!/bin/bash
echo '      _____               .__                       .__		  '
echo '     /  _  \___  _______  |  | _____    ____   ____ |  |__   ____   '
echo '    /  /_\  \  \/ /\__  \ |  | \__  \  /    \_/ ___\|  |  \_/ __ \  '
echo '   /    |    \   /  / __ \|  |__/ __ \|   |  \  \___|   Y  \  ___/  '
echo '   \____|__  /\_/  (____  /____(____  /___|  /\___  >___|  /\___  > '
echo '           \/           \/          \/     \/     \/     \/     \/  '

echo '### Updating packages...'
sudo apt-get update -y
sudo apt-get install -y jq

echo '### Importing scripts...'
cd $HOME && mkdir bin
git clone https://github.com/tdeso/avalanche_node.git
sudo install -m 755 $HOME/avalanche_node/*.sh $HOME/bin
rm -rf avalanche_node
git clone https://github.com/jzu/bac.git 
sudo install -m 755 $HOME/bac/bac $HOME/bin
sudo install -m 644 $HOME/bac/bac.sigs /usr/local/etc
rm -rf bac

echo '### Installing Go...'
wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/bin:$PATH" >> $HOME/.bash_profile

# Setting some variables before sourcing .bash_profile
echo 'export bold=$(tput bold)
export underline=$(tput smul)
export normal=$(tput sgr0)' >> $HOME/.bash_profile
# end of variables

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

#Asking for VPS public IP
while true; do
    read -p "${bold}Do you wish to use the "--ip-address=" launch option (recommended) ? [Y/n] {normal}" yn
    case $yn in
        [Nn]*) exit;;
        [Yy]*|"")
            while true; do
		echo -e "Please enter the public IP address of this machine: "
                read PUBLIC_IP
                while true; do
                    read -p "${bold}You entered $PUBLIC_IP, is it correct ? [Y/n] {normal}" conf
                    case $conf in
                        [Nn]*) break 1;;
                        [Yy]*|"")
                                sed -i "/ARG1/s/$/$PUBLIC_IP/" /etc/.avalanche.conf
                                sed -i '/ExecStart/s/$/ \$ARG1/' /etc/systemd/system/avalanche.service
                                break 3;;
			*) echo "Please answer yes or no.";;
                    esac
                done
            done;;
        *) echo "Please answer yes or no.";;
    esac
done

echo '### Creating Avalanche auto-update service'
sudo USER=$USER bash -c 'cat <<EOF > /etc/systemd/system/monitor.service
[Unit]
Description=Avalanche update monitoring service
After=network.target

[Service]
User=$USER
Group=$USER

WorkingDirectory='$HOME'/bin
ExecStart='$HOME'/bin/monitor.sh

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF'

#Asking for automatic updates
confirm() {
    # call with a prompt string or use a default
   read -r -p "${1:-Are you sure? [Y/n]} " response
    case "$response" in
        [yY]*|"")
            true
            ;;
        *)
            false
            ;;
    esac
}
confirm "${bold}Do you wish to enable automatic updates? [Y/n] {normal}" && echo '### Launching Avalanche monitoring service...' && sudo systemctl {enable,start} monitor

echo '### Launching Avalanche node...'
sudo systemctl {enable,start} avalanche

NODE_ID=$(bac -f info.getNodeID | grep NodeID | awk 'NR==1 {print $2}' | tr -d \")
NODE_STATUS=$(sudo systemctl status avalanche | grep Active | awk 'NR==1 {print $2}' | tr -d \")

if [[ "$NODE_STATUS" == "active" ]]
    then
    echo ''
    echo "${bold}##### AVALANCHE NODE SUCCESSFULLY LAUNCHED #####${normal}"
    echo ''
    echo "${bold}Your NodeID is:${normal}"
    echo "${bold}$NODE_ID${normal}" 
    echo 'Use it to add your node as a validator by following the instructions at:'
    echo "${underline}https://docs.avax.network/v1.0/en/tutorials/adding-validators/#add-a-validator-with-the-wallet${normal}"
    echo ''
    echo 'To monitor the Avalanche node service, type the following commands:'
    echo '    sudo systemctl status avalanche'
    echo '    journalctl -u avalanche'
    echo 'To change the node launch arguments, edit the following file:'
    echo '    /etc/.avalanche.conf'
    echo 'To monitor the node monitoring service, type the following commands:'
    echo '    sudo systemctl status monitor'
    echo '    journalctl -u monitor'
    echo ''
elif [[ "$NODE_STATUS" = "failed" ]]
    then
    echo "${bold}##### AVALANCHE NODE LAUNCH FAILED #####{normal}"
    echo ''
    echo 'To monitor the Avalanche node service, type the following commands:'
    echo '    sudo systemctl status avalanche'
    echo '    journalctl -u avalanche'
    echo 'To change the node launch arguments, edit the following file:'
    echo '    /etc/.avalanche.conf'
    echo 'To monitor the node monitoring service, type the following commands:'
    echo '    sudo systemctl status monitor'
    echo '    journalctl -u monitor'
    echo ''
fi

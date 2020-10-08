#!/bin/bash
# Bash script to install an Avalanche node as a systemd service and automate its updates if desired
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
#wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
#sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
#echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
#echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
#echo "export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/bin:$PATH" >> $HOME/.bash_profile

# Setting some variables before sourcing .bash_profile
echo 'export bold=$(tput bold)
export underline=$(tput smul)
export normal=$(tput sgr0)' >> $HOME/.bash_profile
# end of variables

wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
echo "export PATH=/usr/local/go/bin:$PATH" >> $HOME/.profile
source $HOME/.profile
go version
go env -w GOPATH=$HOME/go
echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
export GOPATH=$HOME/go

# Setting some variables before sourcing .bash_profile
echo 'export bold=$(tput bold)
export underline=$(tput smul)
export normal=$(tput sgr0)' >> $HOME/.bash_profile
# end of variables


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
ExecStart='$GOPATH'/src/github.com/ava-labs/avalanchego/build/avalanchego \$ARG2 \$ARG3

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
sudo USER=$USER bash -c 'cat <<EOF > /etc/systemd/system/monitor.service
[Unit]
Description=Avalanche monitoring service
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

#Asking for launch argument
PUBLIC_IP=$(ip route get 8.8.8.8 | sudo sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
confirm "Do you wish to start your node with the ""--ip-address=" argument ? [Y/n] && sudo sed -i "/ARG1/s/$/$PUBLIC_IP/" /etc/.avalanche.conf ; sudo sed -i '/ExecStart/s/$/ \$ARG1/' /etc/systemd/system/avalanche.service
#Asking for automatic updates
confirm "${bold}Do you wish to enable automatic updates? [Y/n] {normal}" && AUTO_UPDATE=1 && echo '### Launching Avalanche monitoring service...' && sudo systemctl {enable,start} monitor

echo '### Launching Avalanche node...'
sudo systemctl {enable,start} avalanche

if [[ "$AUTO_UPDATE" == 0 ]]; then
journalctl -f -u avaxnode -n 0 | awk '
/<P Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### P CHAIN SUCCESSFULLY BOOTSTRAPPED" }
/<X Chain> snow/engine/avalanche/transitive.go#98: bootstrapping finished/ { print "##### X CHAIN SUCCESSFULLY BOOTSTRAPPED" }
/<C Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### C CHAIN SUCCESSFULLY BOOTSTRAPPED"; exit }'
fi

NODE_ID=$(bac -f info.getNodeID | grep NodeID | awk 'NR==1 {print $2}' | tr -d \")
NODE_STATUS=$(sudo systemctl status avalanche | grep Active | awk 'NR==1 {print $2}' | tr -d \")

if [[ "$NODE_STATUS" == "active" ]]; then
  echo ''
  echo "${bold}##### AVALANCHE NODE SUCCESSFULLY LAUNCHED #####${normal}"
  echo ''
  echo "${bold}Your NodeID is:${normal}"
  echo "${bold}$NODE_ID${normal}" 
  echo 'Use it to add your node as a validator by following the instructions at:'
  echo "${underline}https://docs.avax.network/v1.0/en/tutorials/adding-validators/#add-a-validator-with-the-wallet${normal}"
  echo ''
    if [[ "$AUTO_UPDATE" == 1 ]]; then
      echo 'To disable automatic updates, type the following command:'
      echo '    sudo systemctl stop monitor'
      echo 'To check the node monitoring service status, type the following command:'
      echo '    sudo systemctl status monitor'
      echo 'To check its logs, type the following command:'
      echo '    journalctl -u monitor'
    else
      echo "To update your node, run the update.sh script located at $HOME/bin by using the following command:"
      echo "    cd $HOME/bin && ./update.sh"
      echo 'To enable automatic updates, type the following command:'
      echo '    sudo systemctl {enable,start} monitor'
    fi
  echo ''
  echo 'To monitor the Avalanche node service, type the following command:'
  echo '    sudo systemctl status avalanche'
  echo 'To check its logs, type the following command:'
  echo '    journalctl -u avalanche'
  echo 'To change the node launch arguments, edit the following file:'
  echo '    /etc/.avalanche.conf'
  echo ''
elif [[ "$NODE_STATUS" == "failed" ]]; then
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

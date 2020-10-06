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
sudo systemctl restart {monitor;avalanche}

NODE_STATUS=$(sudo systemctl status avalanche | grep Active | awk 'NR==1 {print $2}' | tr -d \")
if [[ "$NODE_STATUS" == "active" ]]
    then
    echo ''
    echo "${bold}##### AVALANCHE NODE SUCCESSFULLY UPDATED #####${normal}"
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
    echo '${bold}##### AVALANCHE NODE UPDATE FAILED #####{normal}'
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

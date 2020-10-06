#!/bin/bash
# Bash script to update an Avalanche node that runs as a service named avalanche
NODE_VERSION1=$(bac -f info.getNodeVersion | grep version | awk 'NR==1 {print $2}' | sed 's/avalanche//' | tr -d '\/"')
MONITOR_STATUS=$(systemctl -a list-units | grep -F 'monitor' | awk 'NR ==1 {print $4}' | tr -d \")

echo '      _____               .__                       .__		  '
echo '     /  _  \___  _______  |  | _____    ____   ____ |  |__   ____   '
echo '    /  /_\  \  \/ /\__  \ |  | \__  \  /    \_/ ___\|  |  \_/ __ \  '
echo '   /    |    \   /  / __ \|  |__/ __ \|   |  \  \___|   Y  \  ___/  '
echo '   \____|__  /\_/  (____  /____(____  /___|  /\___  >___|  /\___  > '
echo '           \/           \/          \/     \/     \/     \/     \/  '

echo '### Updating packages...'
sudo apt-get -y update

echo '### Updating the repository...'
cd $GOPATH/src/github.com/ava-labs/avalanchego
git pull

echo '### Updating Avalanche node service...'
./scripts/build.sh
if [[ "$MONITOR_STATUS" == "running" ]]; then    
  sudo systemctl restart monitor    
fi
sudo systemctl restart avalanche

NODE_VERSION2=$(bac -f info.getNodeVersion | grep version | awk 'NR==1 {print $2}' | sed 's/avalanche//' | tr -d '\/"')
NODE_STATUS=$(sudo systemctl status avalanche | grep Active | awk 'NR==1 {print $2}' | tr -d \")

if [[ "$NODE_STATUS" == "active" ]] && [[ "$NODE_VERSION1" != "$NODE_VERSION2" ]]; then
  echo ''
  echo "${bold}##### AVALANCHE NODE SUCCESSFULLY UPDATED TO $NODE_VERSION #####${normal}"
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
elif [[ "$NODE_STATUS" == "active" ]] && [[ "$NODE_VERSION1" != "$NODE_VERSION2" ]]; then
  echo ''
  echo "${bold}##### AVALANCHE NODE UPDATE FAILED #####{normal}"
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
elif [[ "$NODE_STATUS" == "failed" ]]; then
  echo ''
  echo "${bold}##### AVALANCHE NODE FAILED TO LAUNCH #####{normal}"
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

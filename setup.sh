#!/bin/bash
# Bash script to setup a VPS and install an Avalanche node with automatic updates

echo '      _____               .__                       .__		  '
echo '     /  _  \___  _______  |  | _____    ____   ____ |  |__   ____   '
echo '    /  /_\  \  \/ /\__  \ |  | \__  \  /    \_/ ___\|  |  \_/ __ \  '
echo '   /    |    \   /  / __ \|  |__/ __ \|   |  \  \___|   Y  \  ___/  '
echo '   \____|__  /\_/  (____  /____(____  /___|  /\___  >___|  /\___  > '
echo '           \/           \/          \/     \/     \/     \/     \/  '

# Basic Yes/no prompt
# Call with a prompt string or use a default
function confirm() {
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

# Add the new user account
# Arguments:
#   Account Username
#   Account Password
#   Flag to determine if user account is added silently. (With / Without GECOS prompt)
function addUserAccount() {
    local username=${1}
    local password=${2}
    local silent_mode=${3}

    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --gecos '' "${username}"
    else
        sudo adduser --disabled-password "${username}"
    fi

    echo "${username}:${password}" | sudo chpasswd
    sudo usermod -aG sudo "${username}"
}

# Add the local machine public SSH Key for the new user account
# Arguments:
#   Account Username
#   Public SSH Key
function addSSHKey() {
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

# Execute a command as a certain user
# Arguments:
#   Account Username
#   Command to be executed
function execAsUser() {
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

# Modify the sshd_config file
# shellcheck disable=2116
function changeSSHConfig() {       
    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(RSAAuthentication)([[:space:]]+)(.*)/RSAAuthentication no/' -i /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(UsePAM)([[:space:]]+)(.*)/UsePAM no/' -i /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(KerberosAuthentication)([[:space:]]+)(.*)/KerberosAuthentication no/' -i /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(GSSAPIAuthentication)([[:space:]]+)(.*)/GSSAPIAuthentication no/' -i /etc/ssh/sshd_config
    confirm "Do you wish to change the SSH port ? [Y/n] " && change_port=1 
    if [[ "$change_port" == 1 ]]; then
        read -r -p "What port do you wish to use ? Do not chose the ports 9650 or 9651 : " ssh_port
        sudo sed -re "s/^(\#?)(Port)([[:space:]]+)(.*)/Port $ssh_port/" -i /etc/ssh/sshd_config
    fi
    ssh_port=$(cat /etc/ssh/sshd_config | grep Port[[:space:]] | awk 'NR==1 {print $2}' | tr -d \")
}

# Setup the Uncomplicated Firewall
function setupUfw() {
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow "${ssh_port}"
    sudo ufw allow 9650
    sudo ufw allow 9651
    yes y | sudo ufw enable
}

# Create the swap file based on amount of physical memory on machine (Maximum size of swap is 4GB)
function createSwap() {
   local swapmem=$(($(getPhysicalMemory) * 2))

   # Anything over 4GB in swap is probably unnecessary as a RAM fallback
   if [ ${swapmem} -gt 4 ]; then
        swapmem=4
   fi

   sudo fallocate -l "${swapmem}G" /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
}

# Mount the swapfile
function mountSwap() {
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

# Modify the swapfile settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function tweakSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    sudo sysctl vm.swappiness="${swappiness}"
    sudo sysctl vm.vfs_cache_pressure="${vfs_cache_pressure}"
}

# Save the modified swap settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function saveSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    echo "vm.swappiness=${swappiness}" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=${vfs_cache_pressure}" | sudo tee -a /etc/sysctl.conf
}

# Set the machine's timezone
# Arguments:
#   tz data timezone
function setTimezone() {
    local timezone=${1}
    echo "${1}" | sudo tee /etc/timezone
    sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime # https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
    sudo dpkg-reconfigure -f noninteractive tzdata
}

# Configure Network Time Protocol
function configureNTP() {
    ubuntu_version="$(lsb_release -sr)"

    if [[ $ubuntu_version == '20.04' ]]; then
        sudo systemctl restart systemd-timesyncd
    else
        sudo apt-get update
        sudo apt-get --assume-yes install ntp
    fi
}

# Gets the amount of physical memory in GB (rounded up) installed on the machine
function getPhysicalMemory() {
    local phymem
    phymem="$(free -g|awk '/^Mem:/{print $2}')"
    
    if [[ ${phymem} == '0' ]]; then
        echo 1
    else
        echo "${phymem}"
    fi
}

# Disables the sudo password prompt for a user account by editing /etc/sudoers
# Arguments:
#   Account username
function disableSudoPassword() {
    local username="${1}"

    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

# Reverts the original /etc/sudoers file before this script is ran
function revertSudoers() {
    sudo cp /etc/sudoers.bak /etc/sudoers
    sudo rm -rf /etc/sudoers.bak
}

output_file="output.log"

# Main function for VPS setup
function main() {
    apt-get -y update
    apt-get -y upgrade
    apt-get -y install git
    read -rp "Enter the username of the new user account:" username

    promptForPassword

    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    addUserAccount "${username}" "${password}"

    read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    echo 'Running setup script...'
    logTimestamp "${output_file}"

    exec 3>&1 >>"${output_file}" 2>&1
    confirm "Do you want to disable the sudo password prompt ? [Y/n] : " && disableSudoPassword "${username}"
    addSSHKey "${username}" "${sshKey}"
    changeSSHConfig
    setupUfw

    if ! hasSwap; then
        setupSwap
    fi

    setupTimezone

    echo "Installing Network Time Protocol... " >&3
    configureNTP

    sudo service ssh restart

    cleanup

    echo "Setup Done! Log file is located at ${output_file}" >&3
}

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings "10" "50"
}

function hasSwap() {
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}

# Set timezone
function setupTimezone() {
    echo -ne "Enter the timezone for the server (Default is 'America/New_York'):\n" >&3
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="America/New_York"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3
}

# Keep prompting for the password and password confirmation
function promptForPassword() {
   PASSWORDS_MATCH=0
   while [ "${PASSWORDS_MATCH}" -eq "0" ]; do
       read -s -rp "Enter new UNIX password:" password
       printf "\n"
       read -s -rp "Retype new UNIX password:" password_confirmation
       printf "\n"

       if [[ "${password}" != "${password_confirmation}" ]]; then
           echo "Passwords do not match! Please try again."
       else
           PASSWORDS_MATCH=1
       fi
   done 
}

#-------------------------------

# Avalanche node related scripts
function install_scripts() { 
    cd $HOME && mkdir bin
    git clone https://github.com/tdeso/avalanche_node.git
    sudo install -m 755 $HOME/avalanche_node/*.sh $HOME/bin
    rm -rf avalanche_node
    sudo apt-get install -y jq
    git clone https://github.com/jzu/bac.git 
    sudo install -m 755 $HOME/bac/bac $HOME/bin
    sudo install -m 644 $HOME/bac/bac.sigs /usr/local/etc
    rm -rf bac
}

# Go Installation
function install_go() {
    wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
    echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
    echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
    echo "export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/bin" >> $HOME/.bash_profile
    go env -w GOPATH=$HOME/go
}

# build avalanchego
function install_avalanche() {
cd $HOME
go get -v -d github.com/ava-labs/avalanchego/...
cd $GOPATH/src/github.com/ava-labs/avalanchego
./scripts/build.sh

# Write avalanche.service with a conf file to edit arguments easily
function avalanche_service() {
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

#Asking for launch argument
PUBLIC_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
confirm "Do you wish to start your node with the ""--ip-address=" argument ? [Y/n] && sed -i "/ARG1/s/$/$PUBLIC_IP/" /etc/.avalanche.conf ; sed -i '/ExecStart/s/$/ \$ARG1/' /etc/systemd/system/avalanche.service
}

# Write auto-update service
function auto-update() {
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

confirm "${bold}Do you wish to enable automatic updates? [Y/n] {normal}" && AUTO_UPDATE=1 && echo 'Launching Avalanche monitoring service...' && sudo systemctl {enable,start} monitor
}

# Launch node, print a message when every chain is done bootstrapping and get the NodeID and Node status as variables
function launch_node() {
sudo systemctl {enable,start} avalanche

if [[ "$AUTO_UPDATE" == 0 ]]; then
journalctl -f -u avaxnode -n 0 | awk '
/<P Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### P CHAIN SUCCESSFULLY BOOTSTRAPPED" }
/<X Chain> snow/engine/avalanche/transitive.go#98: bootstrapping finished/ { print "##### X CHAIN SUCCESSFULLY BOOTSTRAPPED" }
/<C Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### C CHAIN SUCCESSFULLY BOOTSTRAPPED"; exit }'
fi

NODE_ID=$(bac -f info.getNodeID | grep NodeID | awk 'NR==1 {print $2}' | tr -d \")
NODE_STATUS=$(sudo systemctl status avalanche | grep Active | awk 'NR==1 {print $2}' | tr -d \")
}

# Information about what to do once the script is done
function text() {
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
}

# Node installation
function main_node() {
    echo '### Updating packages...'
    sudo apt-get update -y
    
    echo 'Importing scripts...'
    install_scripts
    
    # Setting some variables before sourcing .bash_profile
    echo 'export bold=$(tput bold)
    export underline=$(tput smul)
    export normal=$(tput sgr0)' >> $HOME/.bash_profile
    source $HOME/.bash_profile
    # end of variables
    
    echo 'Installing Go...'
    install_go
    
    echo 'Installing Avalanche...'
    install_avalanche
    
    echo 'Creating Avalanche auto-update service...'
    auto-update
    
    echo 'Launching Avalanche node...'
    launch_node
    text
}

main
execAsUser "${username}" "main_node"

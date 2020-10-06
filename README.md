# Avalanche Automation scripts

## Introduction

This is a small collection of scripts that automates [installing an Avalanche node](https://docs.avax.network/v1.0/en/quickstart/) and monitors it, updating it when a new avalanchego [release](https://github.com/ava-labs/avalanchego/releases/) is available.
The goal is to make staking as easy as possible.

## Requirements

Have a machine that meets the following requirements:
* Hardware: 2 GHz or faster CPU, 4 GB RAM, 2 GB hard disk.
* OS: Ubuntu >= 18.04
* Ports 9650 and 9651 open

## What does it do?
There are three scripts that work with eachother: 
* install.sh installs the node and the monitoring service.  
* update.sh updates the node, it is launched automatically if you chose so whenever the monitoring service detects that an update is available.  
* monitor.sh is the script that is ran as a service to detect when an update is available. It also prints a message when a chain is done bootstrapping.  

## Usage

  1. Connect to your VPS
  2. Run the following command to launch the installation script:
```shell
curl -s https://raw.githubusercontent.com/tdeso/avalanche_node/master/install.sh | bash
```
  3. You'll be asked two things:
  * To chose if you want to start your node with the `--ip-adress` argument which is recommended, if yes you will have to type in your machine public IP, for more information read [this](https://docs.avax.network/v1.0/en/tutorials/adding-validators/#requirements).
  * To chose if you want to enable automatic updates.
  4. Once done, your node will finish installing and display your NodeID, save it and follow [these instructions](https://docs.avax.network/v1.0/en/tutorials/adding-validators/#add-a-validator-with-the-wallet) to start validating the main network.
  5. Congratulations ! You're now validating the main network and earning up to 12% APR on your stake.

## Post-installation
 
 ### Backup your staking key
- To backup your staking key, save the folder located at `~/go/src/github.com/ava-labs/.avalanchego/staking/`somewhere safe.
- To do that, open a terminal on macOS or powershell on Windows and execute the following command: 
(do not forget to replace by the port you connect to ssh, your IP address and the path to the local folder where you want to backup your key)
```shell
scp -r -P [PORT] user@[XX.XX.XX.XX]:$HOME/go/src/github.com/ava-labs/.avalanchego/staking/ Path/to/local/folder
```
### Monitoring
  - To view the logs of your node, execute the following command:
```shell
journalctl -u avaxnode.service
```
  - To modify launch arguments of avalanchego, please edit `/etc/.avavalanche.conf`

## Credits

This is inspired from [ablock.io](https://github.com/ablockio/AVAX-node-installer) script, with multiple additions and modifications.  
It leverages [basic avalanche cli](https://github.com/jzu/bac), which is Unix CLI wrapper around the Avalanche JSON API that makes issuing simple calls easier.

## Licence
[MIT](https://choosealicense.com/licenses/mit/)

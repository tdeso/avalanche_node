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
* install.sh installs the node and the monitoring service
* update.sh updates the node, it is launched automatically whenever the monitoring service detects that an update is available.
* monitoring.sh is the scripts that is ran as a service to detect when an update is available. It also prints a message when a chain is done bootstrapping.

## Usage

  1. Connect to your VPS
  2. Run the following command to launch the installation script:
```shell
curl -s https://raw.githubusercontent.com/tdeso/avalanche_node/master/install.sh | bash
```
  3. You'll be prompted to chose wether or not you want to start your node with the `--ip-adress` argument which is recommended, for more information read [this](https://docs.avax.network/v1.0/en/tutorials/adding-validators/#requirements).
  4. Once done, your node will finish installing and display your NodeID, save it and follow [these instructions](https://docs.avax.network/v1.0/en/tutorials/adding-validators/#add-a-validator-with-the-wallet) to start validating the main network.
  5. Congratulations ! You're now validating the main network and earning up to 12% APR on your stake.
     Your node will update itself automatically whenever an update is avalaible.

## Post-installation
 
 1. Do a backup of your staking key.
```shell
scp -r -P XXXX user@XX.XX.XX.XX:/home/avalanche-user/go/src/github.com/ava-labs/.avalanchego/staking/ $HOME/avalanche
```
  2. To view the logs, execute the following command:
```shell
journalctl -u avaxnode.service
```
  3. To modify launch arguments of avalanchego, please edit `/etc/.avavalanche.conf`

  4. You can add a Keystore user to your node using the `bac -f keystore.createUser : [username], [password]` command , do not forget to back up your user.

## Credits

This is heavily inspired from [ablock.io](https://github.com/ablockio/AVAX-node-installer) script, with multiple additions and modifications.
It leverages [basic avalanche cli](https://github.com/jzu/bac), which is Unix CLI wrapper around the Avalanche JSON API that makes issuing simple calls easier.

## Licence
[MIT](https://choosealicense.com/licenses/mit/)

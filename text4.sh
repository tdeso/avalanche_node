#!/bin/bash

sudo USER=$USER bash -c 'cat <<EOF > $HOME/perso/service.txt
[Unit]
Description=Avalanche node service
After=network.target

[Service]
User=$USER
Group=$USER
EOF'
echo 'done'

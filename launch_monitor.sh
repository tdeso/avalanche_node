#!/bin/bash

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

sudo enable avaxmonitoring
sudo start avaxmonitoring

#!/bin/bash

read -p "Enter your VPS public IP: "  PUBLIC_IP 
sudo bash -c 'cat <<EOF > /etc/.avaxnodeconf
ARG1=--public-ip=$PUBLIC_IP
ARG2=--snow-quorum-size=14
ARG3=--snow-virtuous-commit-threshold=15
EOF'

#!/bin/bash

sudo bash -c 'cat <<EOF > $HOME/perso/testconf
ARG1=--public-ip=$PUBLIC_IP
ARG2=--snow-quorum-size=14
ARG3=--snow-virtuous-commit-threshold=15
EOF'

!/bin/bash

echo "export GOROOT=/usr/local/go" >> $HOME/.bash_profile
echo "export GOPATH=$HOME/go" >> $HOME/.bash_profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
go env -w GOPATH=$HOME/go


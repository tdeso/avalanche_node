#!/bin/bash
journalctl -f -u avaxnode | awk '
                      /You may want to update your client/ { system ("$HOME/bin/update.sh") }
                      /<P Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### P CHAIN SUCCESSFULLY BOOTSTRAPPED" }
                      /<X Chain> snow/engine/avalanche/transitive.go#98: bootstrapping finished/ { print "##### X CHAIN SUCCESSFULLY BOOTSTRAPPED" }
                      /<C Chain> snow/engine/snowman/transitive.go#114: bootstrapping finished/ { print "##### C CHAIN SUCCESSFULLY BOOTSTRAPPED" }'

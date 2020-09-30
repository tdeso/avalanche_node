#!/bin/bash
journalctl -f -u avaxnode | awk 'You may want to update your client { system ("$HOME/bin/update.sh") }'

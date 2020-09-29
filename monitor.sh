#!/bin/bash
journalctl -f -u avaxnode | awk 'You may want to update your client { print | "$HOME/perso/update.sh" }'

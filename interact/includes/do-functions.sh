#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
LOG="$AXIOM_PATH/log.txt"

instances() {
	doctl compute droplet list -o json
}

delete_instance() {
    name="$1"
    force="$2"

    if [ "$force" == "true" ]
        then
        doctl compute droplet delete -f "$name"
    else
        doctl compute droplet delete "$name"
    fi
}

instance_exists() {
	instance="$1"
}

msg_success() {
	echo -e "${BGreen}$1${Color_Off}"
	echo "SUCCESS $(date):$1" >> $LOG
}

msg_error() {
	echo -e "${BRed}$1${Color_Off}"
	echo "ERROR $(date):$1" >> $LOG
}

msg_neutral() {
	echo -e "${Blue}$1${Color_Off}"
	echo "INFO $(date): $1" >> $LOG
}

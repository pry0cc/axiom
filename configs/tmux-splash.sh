#!/bin/bash

if [[ "$(tty)" == "/dev/pts/1" && "$(echo $TMUX | wc -c)" -gt "1" ]]
then
    /etc/update-motd.d/00-header
fi

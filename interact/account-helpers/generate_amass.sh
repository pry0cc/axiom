#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/vars.sh"

securitytrails=""

echo -n -e "${Blue}Would you like to generate a custom amass config? y/[n] (default n): ${Color_Off}"
read ans

if [[ "$ans" == "y" ]];
then   
    tmp_config="$AXIOM_PATH/tmp/$RANDOM"
    cp "$AXIOM_PATH/configs/config.ini" "$tmp_config"
    echo -e "${Green}${Color_Off}"
    echo -n -e "${Blue}Please enter your securitytrails key:${Color_Off}"
    read securitytrails
    if [[ "$securitytrails" != "" ]]; then
        echo -e "[data_sources.SecurityTrails]\nttl = 1440\n[data_sources.SecurityTrails.Credentials]\napikey = $securitytrails\n" >> "$tmp_config"
    fi
    
    mv "$tmp_config" "$AXIOM_PATH/configs/config.ini"
fi



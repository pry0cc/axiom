#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/appliance.sh"
LOG="$AXIOM_PATH/log.txt"

# takes no arguments, outputs JSON object with instances
instances() {
	az vm list-ip-addresses
}

instance_id() {
	name="$1"
	az vm list | jq -r ".[] | select(.name==\"$name\") | .id"
}

# takes one argument, name of instance, returns raw IP address
instance_ip() {
	name="$1"
	az vm list-ip-addresses | jq -r ".[].virtualMachine | select(.name==\"$name\") | .network.publicIpAddresses[].ipAddress"
}

instance_ip_cache() {
	name="$1"
	cat "$AXIOM_PATH"/.sshconfig | grep -A 1 "$name" | awk '{ print $2 }' | tail -n 1
}

instance_list() {
	 az vm list | jq -r '.[].name'
}

# takes no arguments, creates an fzf menu
instance_menu() {
	 az vm list | jq -r '.[].name' | fzf
}

quick_ip() {
	data="$1"
	ip=$(az vm list-ip-addresses | jq -r ".[].virtualMachine | select(.name==\"$name\") | .network.publicIpAddresses[].ipAddress")
	echo $ip
}

# create an instance, name, image_id (the source), sizes_slug, or the size (e.g 1vcpu-1gb), region, boot_script (this is required for expiry)
create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"

	location="$(az account list-locations | jq -r ".[] | select(.name==\"$region\") | .displayName")"
	az vm create --resource-group axiom --name "$name" --image "$image_id" --location "$location" --size "$size_slug"  >/dev/null 2>&1 
	az vm open-port --resource-group axiom --name "$name" --port 0-65535 >/dev/null 2>&1 
	sleep 10
}

instance_pretty() {
	data=$(instances)
	extra_data=$(az vm list)

	(i=0
	echo '"Instance","IP","Size","Region","$M"'

	for instance in $(echo $data | jq -c '.[].virtualMachine');
	do
		#echo $instance
		name=$(echo $instance | jq -r '.name')
		size=$(echo $extra_data | jq -r ".[] | select(.name==\"$name\") | .hardwareProfile.vmSize")
		region=$(echo $extra_data | jq -r ".[] | select(.name==\"$name\") | .location")
		price_monthly=$(cat $AXIOM_PATH/pricing/azure.json | jq -r ".[].costs[] | select(.id==\"$size\") | .firstParty[].meters[].amount")
		i=$(echo "$i+$price_monthly" | bc -l)

		data=$(echo $instance | jq ".size=\"$size\"" | jq ".region=\"$region\"" | jq ".price_monthly=\"$price_monthly\"")
		echo $data | jq -r '[.name, .network.publicIpAddresses[].ipAddress, .size, .region,.price_monthly] | @csv'
	done

	echo "\"_\",\"_\",\"_\",\"Total\",\"\$$i\"") | column -t -s, | tr -d '"' | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'

	i=0
	#for f in $(echo $data | jq -r '.[].size.price_monthly'); do new=$(expr $i + $f); i=$new; done
	#(echo "Instance,IP,Region,\$/M" && echo $data |  jq -r '.[].virtualMachine | [.name,.network.publicIpAddresses[].ipAddress, .region, .price_monthly] | @csv' && echo "_,_,_,Total,\$$i") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
}

# identifies the selected instance/s
selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

get_image_id() {
	query="$1"
	images=$(az image list)
	name=$(echo $images | jq -r ".[].name" | grep "$query" | tail -n 1)
	id=$(echo $images |  jq -r ".[] | select(.name==\"$name\") | .id")
	echo $id
}
#deletes instance, if the second argument is set to "true", will not prompt
delete_instance() {
    name="$1"
    force="$2"

    if [ "$force" == "true" ]; then
        az vm delete --name "$name" --resource-group axiom --yes
    else
    	az vm delete --name "$name" --resource-group axiom
    fi
}

# TBD 
instance_exists() {
	instance="$1"
}

list_regions() {
    az account list-locations | jq -r '.[].displayName'
}

regions() {
	az account list-locations
}

instance_sizes() {
    az vm list-sizes --location "East US"
}

snapshots() {
	az image list
}
# Delete a snapshot by its name
delete_snapshot() {
	name="$1"
	
	az image delete --name "$name" --resource-group axiom
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

# takes any number of arguments, each argument should be an instance or a glob, say 'omnom*', returns a sorted list of instances based on query
# $ query_instances 'john*' marin39
# Resp >>  john01 john02 john03 john04 nmarin39
query_instances() {
	droplets="$(instances)"
	selected=""

	for var in "$@"; do
		if [[ "$var" =~ "*" ]]
		then
			var=$(echo "$var" | sed 's/*/.*/g')
			selected="$selected $(echo $droplets | jq -r '.[].virtualMachine.name' | grep "$var")"
		else
			if [[ $query ]];
			then
				query="$query\|$var"
			else
				query="$var"
			fi
		fi
	done

	if [[ "$query" ]]
	then
		selected="$selected $(echo $droplets | jq -r '.[].virtualMachine.name' | grep -w "$query")"
	else
		if [[ ! "$selected" ]]
		then
			echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
			exit
		fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

query_instances_cache() {
	selected=""

	for var in "$@"; do
		if [[ "$var" =~ "*" ]]
		then
			var=$(echo "$var" | sed 's/*/.*/g')
			selected="$selected $(cat "$AXIOM_PATH"/.sshconfig | grep "Host " | awk '{ print $2 }' | grep "$var")"
		else
			if [[ $query ]];
			then
				query="$query\|$var"
			else
				query="$var"
			fi
		fi
	done

	if [[ "$query" ]]
	then
		selected="$selected $(cat "$AXIOM_PATH"/.sshconfig | grep "Host " | awk '{ print $2 }' | grep -w "$query")"
	else
		if [[ ! "$selected" ]]
		then
			echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
			exit
		fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

# take no arguments, generate a SSH config from the current Digitalocean layout
generate_sshconfig() {
	boxes="$(az vm list-ip-addresses)"
	echo -n "" > $AXIOM_PATH/.sshconfig.new

	for name in $(echo "$boxes" | jq -r '.[].virtualMachine.name')
	do 
		ip=$(echo "$boxes" | jq -r ".[].virtualMachine | select(.name==\"$name\") | .network.publicIpAddresses[].ipAddress")
		echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $AXIOM_PATH/.sshconfig.new
    echo -e "ServerAliveInterval 60" >> $AXIOM_PATH/.sshconfig.new
	done
	mv $AXIOM_PATH/.sshconfig.new $AXIOM_PATH/.sshconfig
	
	if [ "$key" != "null" ]
	then
		gen_app_sshconfig
	fi
}


# Check if host is in .sshconfig, and if it's not, regenerate sshconfig
conf_check() {
	instance="$1"

	l="$(cat "$AXIOM_PATH/.sshconfig" | grep "$instance" | wc -l | awk '{ print $1 }')"

	if [[ $l -lt 1 ]]
	then
		generate_sshconfig	
	fi
}

###################
###### DNS
# List DNS records for domain
list_dns() {
	domain="$1"

	doctl compute domain records list "$domain"
}

list_domains_json() {
    doctl compute domain list -o json
}

# List domains
list_domains() {
	doctl compute domain list
}

list_subdomains() {
    domain="$1"

    doctl compute domain records list $domain -o json | jq '.[]'
}
# get JSON data for snapshots

delete_record() {
    domain="$1"
    id="$2"

    doctl compute domain records delete $domain $id
}

delete_record_force() {
    domain="$1"
    id="$2"

    doctl compute domain records delete $domain $id -f
}
add_dns_record() {
    subdomain="$1"
    domain="$2"
    ip="$3"

    doctl compute domain records create $domain --record-type A --record-name $subdomain --record-data $ip
}



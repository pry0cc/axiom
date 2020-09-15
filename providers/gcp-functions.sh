#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
LOG="$AXIOM_PATH/log.txt"

# takes no arguments, outputs JSON object with instances
instances() {
	gcloud compute instances list --format=json
}

get_image_id() {
	query="$1"
	images=$(gcloud compute images list --format=json)
	name=$(echo $images | jq -r ".[].name" | grep "$query" | tail -n 1)
	id=$(echo $images |  jq -r ".[] | select(.name==\"$name\") | .id")

	echo $id
}


# takes one argument, name of instance, returns raw IP address


instance_ip() {
	host="$1"
	instances | jq -r ".[] | select(.name==\"$host\") | .networkInterfaces[].accessConfigs[].natIP"
}

# takes no arguments, creates an fzf menu
instance_menu() {
	instances | jq '.[].name' | tr -d '"'
}

instance_list() {
	instances | jq -r '.[].name'
}
# identifies the selected instance/s
selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

#

instance_id() {
    name="$1"
	instances | jq ".[] | select(.name==\"$name\") | .id"
}

get_zone() {
	name="$1"

	instances | jq -r ".[] | select(.name=\"$name\") | .zone" | cut -d "/" -f 9 | head -n 1
}

#deletes instance, if the second argument is set to "true", will not prompt
delete_instance() {
    name="$1"
    force="$2"
    zone=$(get_zone "$name")

    if [ "$force" == "true" ]
    then
        gcloud compute instances delete -q "$name" --zone="$zone" 2>&1 >>/dev/null &
    else
        gcloud compute instances delete "$name" --zone="$zone" 2>&1 >>/dev/null &
    fi
}

# TBD 
instance_exists() {
	instance="$1"
}

list_regions() {
      gcloud compute regions list
}


regions() {
     gcloud compute regions list --format=json
}

instance_sizes() {
    gcloud compute machine-types list --format=json
}

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
snapshots() {
	 gcloud compute images list --format=json
}

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
# Delete a snapshot by its name
delete_snapshot() {
	name="$1"
	
	gcloud compute images "$name" -q
}

add_dns_record() {
    subdomain="$1"
    domain="$2"
    ip="$3"

    doctl compute domain records create $domain --record-type A --record-name $subdomain --record-data $ip
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
			selected="$selected $(echo $droplets | jq -r '.[].name' | grep "$var")"
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
		selected="$selected $(echo $droplets | jq -r '.[].name' | grep -w "$query")"
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


quick_ip() {
	data="$1"
	#ip=$(echo $droplets | jq -r ".[] | select(.name == \"$name\") | .networks.v4[].ip_address")
	ip=$(echo $data | jq -r ".[] | select(.name == \"$name\") | .networkInterfaces[].accessConfigs[].natIP")
	echo $ip
}

# take no arguments, generate a SSH config from the current Digitalocean layout
generate_sshconfig() {
	droplets="$(instances)"
	echo -n "" > $AXIOM_PATH/.sshconfig.new

	for name in $(echo "$droplets" | jq -r '.[].name')
	do 
		ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .networkInterfaces[].accessConfigs[].natIP")
		echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $AXIOM_PATH/.sshconfig.new
	done
	mv $AXIOM_PATH/.sshconfig.new $AXIOM_PATH/.sshconfig
}

# create an instance, name, image_id (the source), sizes_slug, or the size (e.g 1vcpu-1gb), region, boot_script (this is required for expiry)
create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"
	domain="example.com"

	gcloud beta compute instances create "$name" --image "$image_id" --zone "$region" --machine-type="$size_slug" 2>&1 >>/dev/null
	sleep 15
}

instance_pretty() {
	data=$(instances)
	i=0
	for f in $(echo $data | jq -r '.[].name'); do new=$(expr $i +  25); i=$new; done
	(
		echo "Instance,IP,Region,Memory,\$/M"
		iter=$(echo $data | jq -r '.[] | [.name, .networkInterfaces[].accessConfigs[].natIP, .zone, .machineType, 25] | @csv')

		for line in $iter
		do
			name=$(echo $line |  cut -d "," -f 1)
			ip=$(echo $line |  cut -d "," -f 2)
			zone=$(echo $line |  cut -d "," -f 3 | cut -d "/" -f 9)
			machine=$(echo $line |  cut -d "," -f 4 | cut -d "/" -f 11)
			price_monthly=$(echo $line |  cut -d "," -f 5)

			echo "$name,$ip,$zone,$machine,$price_monthly"
		done
		echo "_,_,Total,\$$i"
	) | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
	# doctl: (echo "Instance,IP,Region,Memory,\$/M" && echo $data | jq  -r '.[] | [.name, .networks.v4[].ip_address, .region.slug, .size_slug, .size.price_monthly] | @csv' && echo "_,_,To    tal,\$$i") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
		
	#(echo "Instance,IP,Region,Memory,\$/M" && echo $data | jq  -r '.[] | [.name, .networks.v4[].ip_address, .region.slug, .size_slug, .size.price_monthly] | @csv' && echo "_,_,To    tal,\$$i") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
}
# Function used for splitting $src across $instances and rename the split files.
lsplit() {
	src="$1"
	instances=$2
	total=$(echo $instances|  tr ' ' '\n' | wc  -l | awk '{ print $1 }')
	orig_pwd=$(pwd)

	lines=$(wc -l $src | awk '{ print $1 }')
	lines_per_file=$(bc <<< "scale=2; $lines / $total" | awk '{print int($1+0.5)}')
	id=$(echo "$instances" | md5sum | awk '{ print $1 }' |  head -c5)
	split_dir="$AXIOM_PATH/tmp/$id"

	rm  -rf $split_dir  >> /dev/null  2>&1
	mkdir -p $split_dir
	cp $src $split_dir

	cd $split_dir
	split -l $lines_per_file $src
	rm $src
	a=1

	for f in $(ls | grep x)
	do
		mv $f $a.txt
		a=$((a+1))
	done

	i=1
	for instance in $(echo $instances | tr ' ' '\n')
	do
		mv $i.txt $instance.txt
		i=$((i+1))
	done
	
	cd $orig_pwd
	echo -n $split_dir
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


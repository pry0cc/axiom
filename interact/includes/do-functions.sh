#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
LOG="$AXIOM_PATH/log.txt"

instances() {
	doctl compute droplet list -o json
}

instance_ip() {
	name="$1"
	instances | jq -r ".[] | select(.name==\"$name\") | .networks.v4[].ip_address"
}

instance_menu() {
	instances | jq -r '.[].name' | fzf
}

selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
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

list_dns() {
	domain="$1"

	doctl compute domain records list "$domain"
}

list_domains() {
	doctl compute domain list
}

snapshots() {
	doctl compute snapshot list -o json
}
delete_snapshot() {
	name="$1"

	snapshot_data=$(snapshots)
	snapshot_id=$(echo $snapshot_data | jq -r ".[] | select(.name==\"$snapshot\") | .id")
	
	doctl compute snapshot delete "$snapshot_id" -f
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

generate_sshconfig() {
	droplets="$(instances)"
	echo -n "" > $AXIOM_PATH/.sshconfig.new

	for name in $(echo "$droplets" | jq -r '.[].name')
	do 
		ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .networks.v4[].ip_address")
		echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $AXIOM_PATH/.sshconfig.new
	done
	mv $AXIOM_PATH/.sshconfig.new $AXIOM_PATH/.sshconfig
}

create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"

	doctl compute droplet create "$name" --image "$image_id" --size "$size" --region "$region" --wait --user-data-file "$boot_script" 2>&1 >>/dev/null &
}

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


conf_check() {
	instance="$1"

	l="$(cat "$AXIOM_PATH/.sshconfig" | grep "$instance" | wc -l | awk '{ print $1 }')"

	if [[ $l -lt 1 ]]
	then
		generate_sshconfig	
	else
		generate_sshconfig &
	fi
}



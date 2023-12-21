#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
LOG="$AXIOM_PATH/log.txt"

# takes no arguments, outputs JSON object with instances
instances() {
ibmcloud sl vs list --column datacenter --column domain --column hostname --column id --column cpu --column memory --column public_ip --column private_ip --column power_state --column created_by --column action --output json
	#ibmcloud  sl vs list --output json
}

poweron() {
instance_name="$1"
force="$2"
if [ "$force" == "true" ]
then
ibmcloud sl vs power-on $(instance_id $instance_name) --force
else
ibmcloud sl vs power-on $(instance_id $instance_name)
fi
}

poweroff() {
instance_name="$1"
force="$2"
if [ "$force" == "true" ]
then
ibmcloud sl vs power-off $(instance_id $instance_name) --force
else
ibmcloud sl vs power-off $(instance_id $instance_name) 
fi
}

reboot(){
instance_name="$1"
force="$2"
if [ "$force" == "true" ]
then
ibmcloud sl vs reboot $(instance_id $instance_name) --force
else
ibmcloud sl vs reboot $(instance_id $instance_name) 
fi
}

get_image_id() {
	query="$1"
	images=$(ibmcloud sl image list --private --output json)
	name=$(echo $images | jq -r ".[].name" | grep -wx "$query" | tail -n 1)
	id=$(echo $images |  jq -r ".[] | select(.name==\"$name\") | .id")

	echo $id
}

get_snapshots() {
	ibmcloud sl image list --private
}

delete_snapshot() {
 name=$1
 image_id=$(get_image_id "$name")	
 ibmcloud sl image delete "$image_id"
}

snapshots() {
	ibmcloud sl image list --output json --private
}

instance_ip_cache() {
	name="$1"
    config="$2"
    ssh_config="$AXIOM_PATH/.sshconfig"

    if [[ "$config" != "" ]]; then
        ssh_config="$config"
    fi
    cat "$ssh_config" | grep -A 1 "$name" | awk '{ print $2 }' | tail -n 1
}



instance_list() {
	instances | jq -r '.[].hostname'
}
# takes one argument, name of instance, returns raw IP address


instance_ip() {
	host="$1"
	instances | jq -r ".[] | select(.hostname==\"$host\") | .primaryIpAddress"
}

# takes no arguments, creates an fzf menu
instance_menu() {
	instances | jq '.[].hostname' | tr -d '"'
}

# identifies the selected instance/s
selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

#

instance_id() {
    name="$1"
	instances | jq ".[] | select(.hostname==\"$name\") | .id"
}

#deletes instance, if the second argument is set to "true", will not prompt
delete_instance() {
    name="$1"
    force="$2"
    id="$(instance_id $name)"
    if [ "$force" == "true" ]
        then
        ibmcloud sl vs cancel "$id" -f >/dev/null 2>&1
    else
        ibmcloud sl vs cancel "$id"
    fi
}

# TBD 
instance_exists() {
	instance="$1"
}

list_regions() {
#     doctl compute region list
      ibmcloud sl vs options | sed -n '/datacenter/,/Size/p' | tr -s ' ' | rev | cut -d  ' ' -f 1| rev | tail -n +2 | head -n -1 | tr '\n' ','
}

regions() {
#    doctl compute region list -o json
     ibmcloud sl vs options | sed -n '/datacenter/,/Size/p' | tr -s ' ' | rev | cut -d  ' ' -f 1 | rev | tail -n +2 | head -n -1 | tr '\n' ','
}

instance_sizes() {
	echo ""
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
			selected="$selected $(echo $droplets | jq -r '.[].hostname' | grep "$var")"
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
		selected="$selected $(echo $droplets | jq -r '.[].hostname' | grep -w "$query")"
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
    ssh_conf="$AXIOM_PATH/.sshconfig"

	for var in "$@"; do
        if [[ "$var" =~ "-F=" ]]; then
            ssh_conf="$(echo "$var" | cut -d "=" -f 2)"
        elif [[ "$var" =~ "*" ]]; then
			var=$(echo "$var" | sed 's/*/.*/g')
            selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep "$var")"
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
        selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep -w "$query")"
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
	ip=$(echo $data | jq -r ".[] | select(.hostname == \"$name\") | .primaryIpAddress")
	echo $ip
}

# Parse generate_sshconfig file in account.json and generate the SSH config specifed
#
generate_sshconfig() {
	accounts=$(ls -l "$AXIOM_PATH/accounts/" | grep "json" | grep -v 'total ' | awk '{ print $9 }' | sed 's/\.json//g')
	current=$(ls -lh ~/.axiom/axiom.json | awk '{ print $11 }' | tr '/' '\n' | grep json | sed 's/\.json//g') > /dev/null 2>&1
	droplets="$(instances)"
        sshnew="$AXIOM_PATH/.sshconfig.new$RANDOM"
	echo -n "" > $sshnew 
	echo -e "\tServerAliveInterval 60\n" >> $sshnew 
	sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
	echo -e "IdentityFile $HOME/.ssh/$sshkey" >> $sshnew 
	generate_sshconfig="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.generate_sshconfig')"

  if [[ "$generate_sshconfig" == "private" ]]; then
  echo -e "Warning your SSH config generation toggle is set to 'Private' for account : $(echo $current)."
  echo -e "axiom will always attempt to SSH into the instances from their private backend network interface. To revert run: axiom-ssh --just-generate"
  for name in $(echo "$droplets" | jq -r '.[].hostname')
  do 
  ip=$(echo "$droplets" | jq -r ".[] | select(.hostname==\"$name\") | .primaryBackendIpAddress")
  echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew 
  done
  mv $sshnew  $AXIOM_PATH/.sshconfig

	elif [[ "$generate_sshconfig" == "cache" ]]; then
	echo -e "Warning your SSH config generation toggle is set to 'Cache' for account : $(echo $current)."
	echo -e "axiom will never attempt to regenerate the SSH config. To revert run: axiom-ssh --just-generate"
	
  # If anything but "private" or "cache" is parsed from the generate_sshconfig in account.json, generate public IPs only
  #
	else 
  for name in $(echo "$droplets" | jq -r '.[].hostname')
	do 
	ip=$(echo "$droplets" | jq -r ".[] | select(.hostname==\"$name\") | .primaryIpAddress")
	echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew 
	done
	mv $sshnew  $AXIOM_PATH/.sshconfig
fi
}

# create an instance, name, image_id (the source), sizes_slug, or the size (e.g 1vcpu-1gb), region, boot_script (this is required for expiry)
create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"
	domain="example.com"
	cpu="$(jq -r '.cpu' $AXIOM_PATH/axiom.json)"
	#ibmcloud sl vs create -H "$name" -D "$domain" -c 2 -m 2048 -d dal12 --image 6018238 --wait 5000 -f  2>&1 >>/dev/null &
	ibmcloud sl vs create -H "$name" -D "$domain" -c "$cpu" -m "$size_slug" -n 1000 -d "$region" --image "$image_id" -f  2>&1 >>/dev/null 
  sleep 260
}

instance_pretty() {
    data=$(instances)
    #number of droplets
    droplets=$(echo $data|jq -r '.[]|.hostname'|wc -l )

    hour_cost=0
    for f in $(echo $data | jq -r '.[].billingItem.hourlyRecurringFee'); do new=$(bc <<< "$hour_cost + $f"); hour_cost=$new; done
    totalhourly_Price=$hour_cost

    hours_used=0
    for f in $(echo $data | jq -r '.[].billingItem.hoursUsed'); do new=$(bc <<< "$hours_used + $f"); hours_used=$new; done
    totalhours_used=$hours_used

    monthly_cost=0
    for f in $(echo $data | jq -r '.[].billingItem.orderItem.recurringAfterTaxAmount'); do new=$(bc <<< "$monthly_cost + $f"); monthly_cost=$new; done
    totalmonthly_Price=$monthly_cost

    header="Instance,Primary Ip,Backend Ip,DC,Memory,CPU,Status,Hours used,\$/H,\$/M"
    fields=".[] | [.hostname, .primaryIpAddress, .primaryBackendIpAddress, .datacenter.name, .maxMemory, .maxCpu, .powerState.name, .billingItem.hoursUsed, .billingItem.orderItem.hourlyRecurringFee, .billingItem.orderItem.recurringAfterTaxAmount ] | @csv"
    totals="_,_,_,_,Instances,$droplets,Total Hours,$totalhours_used,\$$totalhourly_Price/hr,\$$totalmonthly_Price/mo" 

    #data is sorted by default by field name    
    data=$(echo $data | jq  -r "$fields"| sed 's/^,/0,/; :a;s/,,/,0,/g;ta')
    (echo "$header" && echo "$data" && echo $totals) | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
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

#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/appliance.sh"
LOG="$AXIOM_PATH/log.txt"

poweron() {
  instance_name="$1"
  id=$(instance_id "$instance_name")
  aws ec2 start-instances --instance-ids "$id"
}

poweroff() {
  instance_name="$1"
  id=$(instance_id "$instance_name")
  aws ec2 stop-instances --instance-ids "$id"  | jq -r '.StoppingInstances[0].CurrentState.Name'
}

reboot() {
  instance_name="$1"
  id=$(instance_id "$instance_name")
  aws ec2 reboot-instances --instance-ids "$id"
}

# takes no arguments, outputs JSON object with instances
instances() {
	aws ec2 describe-instances
}

instance_id() {
	name="$1"
	instances | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .InstanceId"
}

# takes one argument, name of instance, returns raw IP address
instance_ip() {
	name="$1"
	instances | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .PublicIpAddress"
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
	instances | jq -r '.Reservations[].Instances[].Tags?[]?.Value?'
}

# takes no arguments, creates an fzf menu
instance_menu() {
	instances | jq -r '.Reservations[].Instances[].Tags?[]?.Value?' | fzf
}

quick_ip() {
	data="$1"
	ip=$(echo $droplets | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .PublicIpAddress")
	echo $ip
}

instance_pretty() {

    type="$(jq -r .default_size "$AXIOM_PATH/axiom.json")"    
    #getCosts
    costs=$(curl -sL 'ec2.shop' -H 'accept: json')
    header="Instance,Primary IP,Backend IP,Region,Type,Status,\$/M"
    fields=".Reservations[].Instances[] | select(.State.Name != \"terminated\") | [.Tags?[]?.Value, .PublicIpAddress, .PrivateIpAddress, .Placement.AvailabilityZone, .InstanceType, .State.Name] | @csv"
	data=$(instances|(jq -r "$fields"|sort -k1))
    #echo "data $data"
    numInstances=$(echo "$data"|grep -v '^$'|wc -l)

    if [[ $numInstances -gt 0  ]];then
        cost=$(echo "$costs"|jq ".Prices[] | select(.InstanceType == \"$type\").MonthlyPrice")
        data=$(echo "$data" | sed "s/$/,\"$cost\" /")
        totalCost=$(echo  "$cost * $numInstances"|bc)
    fi
    footer="_,_,_,Instances,$numInstances,Total,\$$totalCost"
	(echo "$header" && echo "$data" && echo "$footer") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
}

# identifies the selected instance/s
selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

get_image_id() {
	query="$1"
	images=$(aws ec2 describe-images --query 'Images[*]' --owners self)
	name=$(echo $images| jq -r '.[].Name' | grep -wx "$query" | tail -n 1)
	id=$(echo $images |  jq -r ".[] | select(.Name==\"$name\") | .ImageId")
	echo $id
}
#deletes instance, if the second argument is set to "true", will not prompt
delete_instance() {
    name="$1"
    id="$(instance_id "$name")"
    echo "$id"
    aws ec2 terminate-instances --instance-ids "$id" 2>&1 >> /dev/null
}

# TBD 
instance_exists() {
	instance="$1"
}

list_regions() {
    doctl compute region list
}

regions() {
    doctl compute region list -o json | jq -r '.[].slug'
}

instance_sizes() {
    doctl compute size list -o json
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
	aws ec2 describe-images --query 'Images[*]' --owners self 
}

get_snapshots()
{
    header="Name,Creation,Image ID,Size(GB)"
    footer="_,_,_,_"
    fields=".[] | [.Name, .CreationDate, .ImageId, (.BlockDeviceMappings[] | select(.Ebs) | (.Ebs.VolumeSize | tostring))] | @csv"
    data=$(aws ec2 describe-images --query 'Images[*]' --owners self)
	(echo "$header" && echo "$data" | (jq -r "$fields"|sort -k1) && echo "$footer") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
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
    image_id=$(get_image_id "$name")
    snapshot_id="$(aws ec2 describe-images --image-id "$image_id" --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)"
    aws ec2 deregister-image --image-id "$image_id"
    aws ec2 delete-snapshot --snapshot-id "$snapshot_id"
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
			selected="$selected $(echo $droplets | jq -r '.Reservations[].Instances[] | select(.State.Name != "terminated") | .Tags?[]?.Value' | grep "$var")"
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
		selected="$selected $(echo $droplets | jq -r '.Reservations[].Instances[].Tags?[]?.Value' | grep -w "$query")"
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

#  generate the SSH config depending on the key:value of generate_sshconfig in accout.json
# 
generate_sshconfig() {
accounts=$(ls -l "$AXIOM_PATH/accounts/" | grep "json" | grep -v 'total ' | awk '{ print $9 }' | sed 's/\.json//g')
current=$(ls -lh ~/.axiom/axiom.json | awk '{ print $11 }' | tr '/' '\n' | grep json | sed 's/\.json//g') > /dev/null 2>&1
sshnew="$AXIOM_PATH/.sshconfig.new$RANDOM"
droplets="$(instances)"
echo -n "" > $sshnew
echo -e "\tServerAliveInterval 60\n" >> $sshnew
sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
echo -e "IdentityFile $HOME/.ssh/$sshkey" >> $sshnew
generate_sshconfig="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.generate_sshconfig')"

if [[ "$generate_sshconfig" == "private" ]]; then

 echo -e "Warning your SSH config generation toggle is set to 'Private' for account : $(echo $current)."
 echo -e "axiom will always attempt to SSH into the instances from their private backend network interface. To revert run: axiom-ssh --just-generate"
 for name in $(echo "$droplets" | jq -r '.Reservations[].Instances[].Tags?[]?.Value')
 do
 ip=$(echo "$droplets" | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .PublicIpAddress")
 status=$(echo "$droplets" | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .State.Name")
 if [[ "$status" == "running" ]]; then
 	echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
 fi
 done
 mv $sshnew $AXIOM_PATH/.sshconfig

 elif [[ "$generate_sshconfig" == "cache" ]]; then 
 echo -e "Warning your SSH config generation toggle is set to 'Cache' for account : $(echo $current)."
 echo -e "axiom will never attempt to regenerate the SSH config. To revert run: axiom-ssh --just-generate"
	
 # If anything but "private" or "cache" is parsed from the generate_sshconfig in account.json, generate public IPs only
 #
 else
 for name in $(echo "$droplets" | jq -r '.Reservations[].Instances[].Tags?[]?.Value')
 do
 ip=$(echo "$droplets" | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .PublicIpAddress")
 status=$(echo "$droplets" | jq -r ".Reservations[].Instances[] | select(.Tags?[]?.Value==\"$name\") | .State.Name")
 if [[ "$status" == "running" ]]; then
 	echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
 fi
 done
 mv $sshnew $AXIOM_PATH/.sshconfig
fi


 if [ "$key" != "null" ]
 then
 gen_app_sshconfig
 fi
}

create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"
  sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
  #sshkey_fingerprint="$(ssh-keygen -l -E md5 -f ~/.ssh/$sshkey.pub | awk '{print $2}' | cut -d : -f 2-)"
  #keyid=$(doctl compute ssh-key import $sshkey \
  #  --public-key-file ~/.ssh/$sshkey.pub \
  #  --format ID \
  #  --no-header 2>/dev/null) ||
  #keyid=$(doctl compute ssh-key list | grep "$sshkey_fingerprint" | awk '{ print $1 }')
  
  aws ec2 run-instances --image-id "$image_id" --count 1 --instance-type "$size" --region "$region" --security-groups axiom --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" 2>&1 >> /dev/null
  
  sleep 260
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

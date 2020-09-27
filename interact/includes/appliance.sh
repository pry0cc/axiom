#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
key="$(jq -r '.appliance_key?' "$AXIOM_PATH/axiom.json")"
app_name="$(jq -r '.appliance_name?' "$AXIOM_PATH/axiom.json")"
url="$(jq -r '.appliance_url?' "$AXIOM_PATH/axiom.json")"

function appliances() {
	curl -s "$url/heartbeats/$key" | jq
}

appliance_ip() {
	name="$1"

	appliances | jq -r ".[] | select(.name==\"$name\") | .lan_ip"
}

appliance_list() {
	appliances | jq -r '.[].name'
}

function pretty_appliances()  {
	data="$(appliances)"

	(echo "Instance,External IP,Last Seen,Connected,Authenticated,City,Region,ISP,Link" && echo $data | jq -r 'reverse' | jq  -r '.[] | [.name?,.external_ip?,.heartbeat_last_seen?,.connected?,.authenticated?,.geoip?.city?,.geoip?.region?,.geoip.company?.name?,.geoip.asn.type?] | @csv')| sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
	

}

function gen_app_sshconfig() {
	echo "" >> "$AXIOM_PATH/.sshconfig"

	for appliance in $(appliance_list)
	do
		ip=$(appliance_ip "$appliance")
		jump="$app_name"

		echo -e "Host $appliance\n\tHostName $ip\n\tUser root\n\tPort 22\n\tProxyJump $jump\n" >> "$AXIOM_PATH/.sshconfig"
	done
}

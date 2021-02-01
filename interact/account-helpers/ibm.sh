#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/vars.sh"

appliance_name=""
appliance_key=""
appliance_url=""
token=""
region=""
provider=""
size=""
email=""
cpu=""
base_image_id=""
username=""
ibm_cloud_api_key=""


echo -e -n "${Green}Create an IBM Classic API key (for packer) here: https://cloud.ibm.com/iam/apikeys (required): \n>> ${Color_Off}"
read token
while [[ "$token" == "" ]]; do
	echo -e "${BRed}Please provide a IBM Cloud Classic API key, your entry contained no input.${Color_Off}"
	echo -e -n "${Green}Please enter your IBM Cloud Classic API key (required): \n>> ${Color_Off}"
	read token
done
	
echo -e -n "${Green}Create an IBM Cloud API Key (for ibmcli) here: https://cloud.ibm.com/iam/apikeys (required): \n>> ${Color_Off}"
read ibm_cloud_api_key
while [[ "$ibm_cloud_api_key" == "" ]]; do
	echo -e "${BRed}Please provide a IBM Cloud API key, your entry contained no input.${Color_Off}"
	echo -e -n "${Green}Please enter your IBM Cloud API key (required): \n>> ${Color_Off}"
	read ibm_cloud_api_key
done
ibmcloud login --apikey=$ibm_cloud_api_key

echo -e -n "${Green}Please enter your default region: (Default 'sfo2', press enter) \n>> ${Color_Off}"
read region
if [[ "$region" == "" ]]; then
	echo -e "${Blue}Selected default option 'sfo2'${Color_Off}"
	region="sfo2"
fi

echo -e -n "${Green}Please enter your default size: (Default '2048', press enter) \n>> ${Color_Off}"
read size
if [[ "$size" == "" ]]; then
	echo -e "${Blue}Selected default option '2048'${Color_Off}"
    size="2048"
fi

echo -e -n "${Green}Please enter amount of CPU Cores: (E.g '2') \n>> ${Color_Off}"
read cpu
read -p "You need an Ubuntu 20.04 Base Image. Do you want to create one?" yn
case $yn in
	[Yy]* ) bash "$AXIOM_PATH/images/provisioners/ibm-base-image-create.sh";;
	[Nn]* ) echo "Not building base image";;
	* ) echo "Please answer yes or no.";;
esac

echo -e -n "${Green}Please enter Ubuntu 20.04 Base Image ID: (Example: 'ec374a70-bb8e-4207-85ba-6a0c36b6022a') \n>> ${Color_Off}"
read base_image_id
echo -e -n "${Green}Get your SoftLayer username here: https://cloud.ibm.com/iam/users/. Click your username and scroll down to VPN password to get your SoftLayer username (E.g 'SL838382832') \n>> ${Color_Off}"
read username

echo -e -n "${Green}Please enter your GPG Recipient Email (for encryption of boxes): (optional, press enter) \n>> ${Color_Off}"
read email

echo -e -n "${Green}Would you like to configure connection to an Axiom Pro Instance? Y/n (Must be deployed.) (optional, default 'n', press enter) \n>> ${Color_Off}"
read ans

if [[ "$ans" == "Y" ]]; then
    echo -e -n "${Green}Enter the axiom pro instance name \n>> ${Color_Off}"
    read appliance_name

    echo -e -n "${Green}Enter the instance URL (e.g \"https://pro.acme.com\") \n>> ${Color_Off}"
    read appliance_url

    echo -e -n "${Green}Enter the access secret key \n>> ${Color_Off}"
    read appliance_key 
fi

data="$(echo "{\"do_key\":\"$token\",\"ibm_cloud_api_key\":\"$ibm_cloud_api_key\",\"region\":\"$region\",\"provider\":\"ibm\",\"default_size\":\"$size\",\"cpu\":\"$cpu\",\"username\":\"$username\",\"base_image_id\":\"$base_image_id\",\"appliance_name\":\"$appliance_name\",\"appliance_key\":\"$appliance_key\",\"appliance_url\":\"$appliance_url\", \"email\":\"$email\"}")"

echo -e "${BGreen}Profile settings below: ${Color_Off}"
echo $data | jq
echo -e "${BWhite}Press enter if you want to save these to a new profile, type 'r' if you wish to start again.${Color_Off}"
read ans

if [[ "$ans" == "r" ]];
then
    $0
    exit
fi

echo -e -n "${BWhite}Please enter your profile name (e.g 'personal', must be all lowercase/no specials)\n>> ${Color_Off}"
read title

if [[ "$title" == "" ]]; then
    title="personal"
    echo -e "${Blue}Named profile 'personal'${Color_Off}"
fi

echo $data | jq > "$AXIOM_PATH/accounts/$title.json"
echo -e "${BGreen}Saved profile '$title' successfully!${Color_Off}"
$AXIOM_PATH/interact/axiom-account $title
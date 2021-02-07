#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/vars.sh"

client_id=""
client_secret=""
tenant_id=""
sub_id=""
appliance_name=""
appliance_key=""
appliance_url=""
token=""
region=""
provider=""
size=""
email=""
# Packer::Azure CLI auth will use the information from an active az login session to connect to Azure and set the subscription id and tenant id associated to the signed in account. 
# Packer::Azure CLI authentication will use the credential marked as isDefault
use_azure_cli_auth="true"

echo -e -n "${Green}Please enter your default region: (Default 'eastus', press enter) \n>> ${Color_Off}"

read region

if [[ "$region" == "" ]]; then
    echo -e "${Blue}Selected default option 'eastus'${Color_Off}"
    region="eastus"
fi

echo -e -n "${Green}Please enter your default size: (Default 'Standard_B1s)', press enter) \n>> ${Color_Off}"
read size

if [[ "$size" == "" ]]; then
    echo -e "${Blue}Selected default option 'Standard_B1s'${Color_Off}"
    size="Standard_B1s"
fi

az login
az group create -n axiom -l "$region"

bac="$(az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }")" 
client_id="$(echo $bac | jq -r '.client_id')"
client_secret="$(echo $bac | jq -r '.client_secret')"
tenant_id="$(echo $bac | jq -r '.tenant_id')"
sub_id="$(az account show --query "{ subscription_id: id }" | jq -r .subscription_id)"

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

data="$(echo "{\"client_id\":\"$client_id\",\"client_secret\":\"$client_secret\",\"tenant_id\":\"$tenant_id\",\"subscription_id\":\"$sub_id\",\"region\":\"$region\",\"resource_group\":\"axiom\",\"provider\":\"azure\",\"default_size\":\"$size\",\"appliance_name\":\"$appliance_name\",\"appliance_key\":\"$appliance_key\",\"appliance_url\":\"$appliance_url\", \"email\":\"$email\",\"use_azure_cli_auth\":$use_azure_cli_auth}")"

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

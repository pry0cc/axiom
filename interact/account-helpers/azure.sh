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

BASEOS="$(uname)"
case $BASEOS in
'Linux')
    BASEOS='Linux'
    ;;
'FreeBSD')
    BASEOS='FreeBSD'
    alias ls='ls -G'
    ;;
'WindowsNT')
    BASEOS='Windows'
    ;;
'Darwin')
    BASEOS='Mac'
    ;;
'SunOS')
    BASEOS='Solaris'
    ;;
'AIX') ;;
*) ;;
esac

echo -e "${Blue}Installing azure az...${Color_Off}"
if [ $BASEOS == "Mac" ]; then
brew update && brew install azure-cli
fi


if [ $BASEOS == "Linux" ] ; then

OS=$(lsb_release -i | awk '{ print $3 }')
   if ! command -v lsb_release &> /dev/null; then
            OS="unknown-Linux"
            BASEOS="Linux"
   fi
sudo apt-get update -qq
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y -qq
AZ_REPO=$(lsb_release -cs)
if [ $AZ_REPO == "kali-rolling" ]; then
check_version=$(cat /proc/version | awk '{ print $6 $7 }' | tr -d '()' | cut -d . -f 1)
case $check_version in                                
  Debian10)
    AZ_REPO="buster"
    ;;
  Debian11)
    AZ_REPO="bullseye"
    ;;
  Debian12)
    AZ_REPO="bookworm"
    ;;
  *)
esac 
fi
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update -qq
sudo apt-get install azure-cli -y -qq
fi

if [[ $OS == "Arch" ]] || [[ $OS == "ManjaroLinux" ]]; then
curl -L https://aka.ms/InstallAzureCli | bash
fi

echo -e -n "${Green}Please enter your subscription_id: (Press enter if you only have one subscription) \n>> ${Color_Off}"
read sub_id
if [[ "$sub_id" == "" ]]; then
    sub_id="$(az account show --query "{ subscription_id: id }" | jq -r .subscription_id)"
fi
echo -e "${Blue}Selected default subscription_id $sub_id ${Color_Off}"

echo -e -n "${Green}Please enter your default region: (Default 'eastus', press enter) \n>> ${Color_Off}"

read region

if [[ "$region" == "" ]]; then
    echo -e "${Blue}Selected default option 'eastus'${Color_Off}"
    region="eastus"
fi

echo -e -n "${Green}Please enter your default size: (Default 'Standard_B1ls'), press enter) \n>> ${Color_Off}"
read size

if [[ "$size" == "" ]]; then
    echo -e "${Blue}Selected default option 'Standard_B1ls'${Color_Off}"
    size="Standard_B1ls"
fi

echo -e -n "${Green}Please enter your resource group name: (Default 'axiom'), press enter) \n>> ${Color_Off}"
read resource_group

if [[ "$resource_group" == "" ]]; then
    echo -e "${Blue}Selected default option 'axiom'${Color_Off}"
    resource_group="axiom"
fi

echo -e -n "${Green}Please enter your Azure email account: (Example 'test@myazureaccount.com'), press enter) \n>> ${Color_Off}"
read email

if [[ "$email" == "" ]]; then
    echo -e "${BRed}No email provided, the account setup will fail${Color_Off}"
fi

az login 2>/dev/null
az account set --subscription "$sub_id" 2>/dev/null
az group create -l "$region" -n "$resource_group" 2>/dev/null
#az configure --defaults group="$resource_group" 2>/dev/null
az role assignment create --role "Owner" --assignee "$email" -g ${resource_group} 2>/dev/null
az provider register --namespace 'Microsoft.Network' --accept-terms 2>/dev/null
az provider register --namespace 'Microsoft.Compute' --accept-terms 2>/dev/null
bac=$(az ad sp create-for-rbac --role Owner --scopes "/subscriptions/${sub_id}/resourcegroups/${resource_group}" --name ${resource_group} --query "{ client_id: appId, client_secret: password, tenant_id: tenant }") 2>/dev/null
client_id="$(echo $bac | jq -r '.client_id')"
client_secret="$(echo $bac | jq -r '.client_secret')"
tenant_id="$(echo $bac | jq -r '.tenant_id')"

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

data="$(echo "{\"client_id\":\"$client_id\",\"client_secret\":\"$client_secret\",\"tenant_id\":\"$tenant_id\",\"subscription_id\":\"$sub_id\",\"region\":\"$region\",\"resource_group\":\"$resource_group\",\"provider\":\"azure\",\"default_size\":\"$size\",\"appliance_name\":\"$appliance_name\",\"appliance_key\":\"$appliance_key\",\"appliance_url\":\"$appliance_url\", \"email\":\"$email\",\"use_azure_cli_auth\":\"$use_azure_cli_auth\"}")"

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

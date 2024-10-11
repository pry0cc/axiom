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


install_aws_cli() {
  echo -e "${Blue}Installing aws cli...${Color_Off}"
  if [[ $BASEOS == "Mac" ]]; then
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    open AWSCLIV2.pkg
  elif [[ $BASEOS == "Linux" ]]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp
    unzip awscliv2.zip
    sudo ./aws/install
  fi
}

is_installed() {
  command -v "$1" > /dev/null 2>&1
}

if is_installed "aws"; then
  echo -e "${BGreen}aws cli is already installed${Color_Off}"
else
  install_aws_cli
fi

function awssetup() {
  # Look where is the instance axiom is being installed on
  if curl -s http://169.254.169.254/latest/meta-data/instance-id &>/dev/null; then
    onCloud=true
    # Means that the instance is on AWS and skip the Access Key
    # /!\ The instance needs IAM Policies on ec2 to perform installation
    :
  else
    # Doesn't run on AWS and need Access Key
    echo -e -n "${Green}Please enter your AWS Access Key ID (required): \n>> ${Color_Off}"
    read ACCESS_KEY
    while [[ "$ACCESS_KEY" == "" ]]; do
      echo -e "${BRed}Please provide a AWS Access KEY ID, your entry contained no input.${Color_Off}"
      echo -e -n "${Green}Please enter your token (required): \n>> ${Color_Off}"
      read ACCESS_KEY
    done

    echo -e -n "${Green}Please enter your AWS Secret Access Key (required): \n>> ${Color_Off}"
    read SECRET_KEY
    while [[ "$SECRET_KEY" == "" ]]; do
      echo -e "${BRed}Please provide a AWS Secret Access Key, your entry contained no input.${Color_Off}"
      echo -e -n "${Green}Please enter your token (required): \n>> ${Color_Off}"
      read SECRET_KEY
    done

    aws configure set aws_access_key_id "$ACCESS_KEY"
    aws configure set aws_secret_access_key "$SECRET_KEY"
  fi

  default_region="us-west-2"
  echo -e -n "${Green}Please enter your default region: (Default '$default_region', press enter) \n>> ${Color_Off}"
  read region
  if [[ "$region" == "" ]]; then
    echo -e "${Blue}Selected default option '$default_region'${Color_Off}"
    region="$default_region"
  fi
  echo -e -n "${Green}Please enter your default size: (Default 't2.medium', press enter) \n>> ${Color_Off}"
  read size
  if [[ "$size" == "" ]]; then
    echo -e "${Blue}Selected default option 't2.medium'${Color_Off}"
    size="t2.medium"
  fi
  # VPC Selection
  while true; do
    echo -e -n "${Green}Here are the differents VPCs available : \n${Color_Off}"
    #Get all the VPC on the account in the region selected and display them
    aws ec2 describe-vpcs --query "Vpcs[*].[Tags[?Key=='Name'].Value]" --region $region --output text | awk -F'\t' '{if (NR==1) print "Number \t VPC"} {print NR-1 "\t" $1}'
    echo -e -n "${Green}Please enter the vpc number or id you want to use: (Default vpc, press enter) \n>> ${Color_Off}"
    read vpc
    if [[ $vpc == *"vpc"* ]]; then
      vpc_id=$vpc
    else
      vpc_id=$(aws ec2 describe-vpcs --filters --query "Vpcs[$vpc].VpcId" --region $region --output text)
    fi
    # If default VPC choosed, retrieve it
    if [[ "$vpc" == "" ]]; then
      vpc_id=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --region $region --query "Vpcs[0].VpcId" --output text)
      echo -e "${Blue}Selected default option 'default vpc'${Color_Off}"
      if [[ "$vpc_id" == "None" ]]; then
        echo "${BRed}No default vpc available, please choose a vpc.${Color_Off}"
      else
        is_default=true
        break
      fi
    fi
    break
  done
  # Subnet Selection
  while true; do
    echo -e -n "${Green}This vpc has those subnets : \n${Color_Off}"
    if [[ "$is_default" ]]; then
      aws ec2 describe-subnets --filters "Name=vpc-id, Values=$vpc_id" --region $region --query "Subnets[*].[AvailabilityZone]" --output text | awk -F'\t' '{if (NR==1) print "Number \t Availability Zone"} {print NR-1 "\t" $1}'
    else
      aws ec2 describe-subnets --filters "Name=vpc-id, Values=$vpc_id" --region $region --query "Subnets[*].[Tags[?Key=='Name'].Value]" --output text | awk -F'\t' '{if (NR==1) print "Number \t Subnet"} {print NR-1 "\t" $1}'
    fi
    echo -e -n "${Green}Please choose the subnet you want to use: (number required) \n>> ${Color_Off}"
    read subnet
    subnet_id=$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$vpc_id" --region $region --query "Subnets[$subnet].SubnetId" --output text)
    if [[ "$subnet_id" != "None" && $subnet =~ ^[0-9]+$ ]]; then
      break
    else
      echo -e "${BRed}Please provide a subnet, your entry didn't contain a valid input.${Color_Off}"
    fi
  done
  # Tags Selection
  while true; do
    echo -e -n "${Green}Do you need to add a tag to the resources created ? (y/n) \n>> ${Color_Off}"
    read ans
    if [[ "$ans" == "n" || "$ans" == "no" || "$ans" == "" ]]; then
      echo -e "${Blue}No tags needed \n${Color_Off}"
      ami_tags=""
      security_group_tags=""
      break
    elif [[ "$ans" == "y" || "$ans" == "yes" ]]; then
      echo -e -n "${Green}Please enter the key string \n>> ${Color_Off}"
      read tkey
      echo -e -n "${Green}Please enter the value string \n>> ${Color_Off}"
      read tvalue
      security_group_tags="Key=${tkey},Value=${tvalue}"
      break
    else
      echo -e "${BRed}Please provide a correct answer, your entry didn't contain a valid input. \n${Color_Off}"
    fi
  done
  # Security group source filtering Selection
  ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'
  while true; do
    echo -e -n "${Green}Choose the source for the inbound rules (default 0.0.0.0/0). Enter None if not needed. \n>> ${Color_Off}"
    read security_source
    # Validate input
    if [[ $security_source =~ $ip_regex ]]; then
      IFS='/' read -r ip prefix <<<"$ip_cidr"
      IFS='.' read -r -a octets <<<"$ip"
      valid_ip=true
      for octet in "${octets[@]}"; do
        if ((octet < 0 || octet > 255)); then
          echo -e "${BRed}Invalid IP address: Octet $octet is out of range \n${Color_Off}"
          valid_ip=false
          break
        fi
      done
      if ((prefix < 0 || prefix > 32)); then
        echo -e "${BRed}Invalid CIDR prefix: $prefix is out of range \n${Color_Off}"
        valid_ip=false
      fi
      if $valid_ip; then
        break
      fi
    # Accept all IPs if nothing entered
    elif [[ "$security_source" == "" ]]; then
      security_source="0.0.0.0/0"
      echo -e "${Blue}Selected default option '0.0.0.0/0'${Color_Off}"
      break
    # None case
    elif [[ "$security_source" == "None" ]]; then
    echo -e "${Blue}Selected None option${Color_Off}"
      break
    else
      echo -e "${BRed}Please provide a correct answer, your entry didn't contain a valid input. Expected format: x.x.x.x/x \n${Color_Off}"
    fi
  done
  aws configure set default.region "$region"

  echo -e "${BGreen}Creating an Axiom Security Group: ${Color_Off}"

  # Looking if axiom security group already exist
  existing_sec_id="$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc_id Name=group-name,Values=axiom \
    --query 'SecurityGroups[0].GroupId' --output text)"
  aws ec2 delete-security-group --group-id $existing_sec_id >/dev/null 2>&1
  if [[ "$security_group_tags" != "" ]]; then
    sc="$(aws ec2 create-security-group --group-name axiom --vpc-id $vpc_id --description "Axiom SG" --tag-specifications "ResourceType=security-group,Tags=[{${security_group_tags}}]")"
  else
    sc="$(aws ec2 create-security-group --group-name axiom --vpc-id $vpc_id --description "Axiom SG")"
  fi
  group_id="$(echo "$sc" | jq -r '.GroupId')"
  echo -e "${BGreen}Created Security Group: $group_id ${Color_Off}"

  # Create the ssh rule
  if [[ "$security_source" != "None" ]]; then
    group_rules="$(aws ec2 authorize-security-group-ingress --group-id "$group_id" --protocol tcp --port 2266 --cidr $security_source)"
  fi

  # Add the Public IP address of the axiom instance
  if [[ "$onCloud" == true ]]; then
    TOKEN="$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" >/dev/null 2>&1
    publicIP="$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)"
    aws ec2 authorize-security-group-ingress --group-id "$group_id" --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "'"$publicIP"/32'"}]},{"IpProtocol": "udp", "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "'"$publicIP"/32'"}]},{"IpProtocol": "icmp", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "'"$publicIP"/32'"}]}]' >/dev/null 2>&1
  fi
  group_owner_id="$(echo "$group_rules" | jq -r '.SecurityGroupRules[].GroupOwnerId')" >/dev/null 2>&1

  if [[ "$tkey" == "None" ]]; then
    data="$(echo "{\"aws_access_key\":\"$ACCESS_KEY\",\"aws_secret_access_key\":\"$SECRET_KEY\",\"group_owner_id\":\"$group_owner_id\",\"security_group_id\":\"$group_id\",\"region\":\"$region\",\"vpc_id\":\"$vpc_id\",\"subnet_id\":\"$subnet_id\",\"provider\":\"aws\",\"default_size\":\"$size\"}")"
  else
    data="$(echo "{\"aws_access_key\":\"$ACCESS_KEY\",\"aws_secret_access_key\":\"$SECRET_KEY\",\"group_owner_id\":\"$group_owner_id\",\"security_group_id\":\"$group_id\",\"tag_key\":\"$tkey\",\"tag_value\":\"$tvalue\",\"region\":\"$region\",\"vpc_id\":\"$vpc_id\",\"subnet_id\":\"$subnet_id\",\"provider\":\"aws\",\"default_size\":\"$size\"}")"
  fi
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

}

awssetup

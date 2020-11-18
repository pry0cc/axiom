echo "Uploading SSH key"
sshkeyid=$(ibmcloud sl security sshkey-add axiom-ssh-key -f ~/.ssh/id_rsa1.pub -output json | jq '.id' 3>&1); # Upload your SSH key to IBM Cloud & Get ID
echo "SSH Key ID $sshkeyid"; # ssh key id
echo "Creating Ubuntu 18.04 Base VSI";
id=$(echo "Y"| ibmcloud sl vs create -H axiom-base-image -D axiom.local -c 2 -m 4096 -d dal13 -o UBUNTU_18_64 --disk 100 -k $sshkeyid | grep -s "^ID" | tr -s " " | cut -d " " -f 2 ); # create axiom base image with sshkey
echo "Base IBM Cloud Server ID is $id";
echo "sleeping one minute";
sleep 60;
echo "Upgrading Ubuntu 18.04 to Ubuntu 20.04... multiple reboots ahead";
imageip=$(ibmcloud sl vs detail $id -output json | jq '.primaryIpAddress' | tr -d '"'); # Get VSI Public Address

for run in {1..2}; do # loop to upgrade ubuntu 18.04 to 20.04
  ssh -T -o "StrictHostKeyChecking=no" -l root $imageip << EOF
    sudo apt-get update && sudo apt-get dist-upgrade -y && sudo dpkg --configure -a sudo apt-get clean; # clean up after errors
    sudo do-release-upgrade -f DistUpgradeViewNonInteractive;
    sudo reboot; # restart machine
EOF
  echo "sleeping two minutes"
  sleep 120;
done;

echo "Creating Image of Ubuntu 20.04";
ibmcloud sl vs capture $id -n $id --all; # create Image from VSI

imageid=$(ibmcloud sl image list --private | grep $id | cut -d " " -f 1);
echo "Finished! Make sure to copy global_identifier of newly created image";
ibmcloud sl image detail $imageid;

echo "Uploading SSH key"
ibmcloud sl security sshkey-add axiom-ssh-key -f ~/.ssh/id_rsa.pub --note axiom; # Upload your SSH key to IBM Cloud
sshkeyid=$(ibmcloud sl security sshkey-list | grep axiom | cut -d " " -f 1); # Get ssh ky id
echo "SSH Key ID $sshkeyid"; # ssh key id
echo "Creating Ubuntu 18.04 Base VSI"
ibmcloud sl vs create -H axiom-base-image -D axiom.local -c 2 -m 4096 -d dal13 -o UBUNTU_18_64 --disk 100 -k $sshkeyid -f; # create axiom base image with sshkey
echo "sleeping one minute"
sleep 60;
echo "Upgrading Ubuntu 18.04 to Ubuntu 20.04... multiple reboots ahead"
imageip=$(ibmcloud sl vs list | grep axiom-base-image | tr -s " " | cut -d " " -f 6); # Get VSI Public Address

for run in {1..2}; do # loop to upgrade ubuntu 18.04 to 20.04
  ssh -T -o "StrictHostKeyChecking=no" -l root $imageip << EOF
    sudo apt-get update && sudo apt-get dist-upgrade -y && sudo dpkg --configure -a sudo apt-get clean; # clean up after errors
    sudo do-release-upgrade -f DistUpgradeViewNonInteractive;
    sudo reboot; # restart machine
EOF
  echo "sleeping two minutes"
  sleep 120;
done;
vsiid=$(ibmcloud sl vs list | grep axiom-base-image | tr -s " " | cut -d " " -f 1); # get vsi id
echo "Creating Image of Ubuntu 20.04"
ibmcloud sl vs capture $vsiid -n pry --all; # create Image from VSI
imageid=$(ibmcloud sl image list | tail -1 | cut -d " " -f 1);
echo "Finished! Make sure to copy global_identifier of newly created image"
ibmcloud sl image detail $imageid

#!/bin/bash

#set -x

echo "Running automated raspi-config tasks"
sudo apt-get update && sudo apt-get -y upgrade

 
# Via https://gist.github.com/damoclark/ab3d700aafa140efb97e510650d9b1be
# Execute the config options starting with 'do_' below
grep -E -v -e '^\s*#' -e '^\s*$' <<END | \
sed -e 's/$//' -e 's/^\s*/\/usr\/bin\/raspi-config nonint /' | bash -x -
#
 
# Drop this file in SD card root. After booting run: sudo /boot/setup.sh
 
# --- Begin raspi-config non-interactive config option specification ---
 
# Hardware Configuration
#do_boot_wait 0            # Turn on waiting for network before booting
#do_boot_splash 1          # Disable the splash screen
#do_overscan 1             # Enable overscan
#do_camera 0               # Enable the camera
#do_ssh 1                  # Enable remote ssh login
 
# System Configuration
do_configure_keyboard us
do_hostname ${host}
do_change_timezone Europe/Berlin
do_change_locale LANG=de_DE.UTF-8
 
# Don't add any raspi-config configuration options after 'END' line below & don't remove 'END' line
END



##SSH Setup

#Setup public key authentification

sudo mkdir /home/pi/.ssh
touch /home/pi/.ssh/authorized_keys
chmod 700 /home/pi/.ssh
chmod 600 /home/pi/.ssh/authorized_keys
ssh-keygen -f /home/pi/.ssh/id_rsa -q -N ""
cat /home/pi/id_rsa.pub >> /home/pi/authorized_keys
sudo rm /home/pi/id_rsa.pub

sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

#Change Password

passwd

#Prompting to disable Password Authentification

while true; do
read -p "Do you want to leave ssh Password Login enabled? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) 
		    echo "Please copy the id_rsa file from ~/.ssh/ to your machine."
		    read -p "Use the following command: ssh pi@raspberrypi:/.ssh/id_rsa %UserProfile%\\Desktop\\ "
		    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
		    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
		    break ;;
        * ) echo "Please answer yes or no. [y/n] ";;
    esac
done

#Changing SSH Port for security reasons

sudo sed -i 's/#Port 22/Port 784/g' /etc/ssh/sshd_config
sudo sed -i 's/Port 22/Port 784/g' /etc/ssh/sshd_config



##Installing Samba

while true; do
read -p "Do you want to install Samba? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no. [y/n] ";;
    esac
done

sudo apt-get -y install samba samba-common smbclient
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.backup
sudo touch /etc/samba/smb.conf
cat <<EOT >> /etc/samba/smb.conf
[RaspberryPi]
comment = RaspberryPi
path = /home/pi
read only = no
EOT

echo "Please enter a password for your Samba share:"
sudo smbpasswd -a pi



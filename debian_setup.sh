#!/bin/bash

echo Master Custom Script
src_dir=linux_custom

sudo apt install git
git config --global user.name $USER
git config --global user.email $GITUSER

# Pull Dotfiles from repo
cd /home/$USER/
git clone linux-custom
cd $src_dir
sudo apt update


# Check if GUI installed, if yes set gui, else skip certain software
file $(grep -Po "(?<=^Exec=).*" /usr/share/xsessions/budgie-desktop.desktop)
if [[ echo $? -eq 0 ]]; then

	# Add repositories for software
	sudo apt install apt-transport-https ca-certificates curl software-properties-common
	sudo add-apt-repository "deb https://download.sublimetext.com/ apt/stable/"
	sudo add-apt-repository ppa:codeblocks-devs/release
	sudo apt-add-repository "deb https://packages.microsoft.com/ubuntu/20.04/prod"
	sudo add-apt-repository ppa:jtaylor/keepass
	sudo apt-add-repository "deb https://packagecloud.io/github/git-lfs/ubuntu/"
	
	# Install programming software
	sudo apt update
	sudo snap install vscode
	
	# Install utility software
	sudo apt install keepass2 veracrypt wireshark gnome-tweek dconf-editor
	sudo snap install chromium
fi
	
# Install Software
sudo apt install rename tree ffmpeg ufw
sudo python3 -m pip install --upgrade youtube_dl

# Generate SSH keys
ssh-keygen -t ed25519 -C $USER -f $USER/.ssh/ed25519_$USER@$HOSTNAME

# Set UFW and rules
sudo ufw enable
sudo cp ./user.rules /etc/ufw/user.rules
sudo cp ./user6.rules /etc/ufw/user6.rules
sudo ufw reload

# move scripts and make executable
sudo mkdir /scripts
sudo chown $USER:$USER /scripts
cp -avr /home/$USER/$src_dir/scripts /scripts
sudo chmod +x /scripts/*.sh

# edit SSHD_Config file
file="$1"
param[1]="PermitRootLogin "
param[2]="PubkeyAuthentication"
param[3]="AuthorizedKeysFile"
param[4]="PasswordAuthentication"

# main
if [ -z "${file}" ]; then
    file="/etc/ssh/sshd_config"
fi

# backup_sshd_config
if [ -f ${file} ]; then
    sudo cp ${file} ${file}.bak
else
    echo "File ${file} not found."
    exit 1
fi

# edit_sshd_config
for PARAM in ${param[@]}; do
    sudo sed -i '/^'"${PARAM}"'/d' ${file}
    echo "All lines beginning with '${PARAM}' were deleted from ${file}."
done

sudo echo "${param[1]} no" >> ${file}
sudo echo "${param[2]} yes" >> ${file}
sudo echo "${param[3]} ~/.ssh/authorized_keys" >> ${file}
sudo echo "${param[4]} no" >> ${file}

# reload_sshd
sudo systemctl reload sshd.service
echo "Run 'systemctl reload sshd.service'...OK"

#!/bin/bash
#Creating the user
read -p "Please add the user name :" user
adduser $user
#Create password
#Click through prompt
usermod -aG sudo $user

#Creating SSH keys for new user
mkdir /home/$user/.ssh
cp .ssh/authorized_keys /home/ghostrider/.ssh/authorized_keys
chown -R $user:$user /home/ghostrider/.ssh
echo "User $user has been created and configured."

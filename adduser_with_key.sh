#!/bin/bash
#Creating the user
#if you are pulling from git make sure to move the file to the root directory or fix the path for the copy function in this script
read -p "Please add the user name :" user
adduser $user
#Create password
#Click through prompt
usermod -aG sudo $user

#Creating SSH keys for new user
mkdir /home/$user/.ssh
cp .ssh/authorized_keys /home/$user/.ssh/authorized_keys
chown -R $user:$user /home/$user/.ssh
echo "User $user has been created and configured."

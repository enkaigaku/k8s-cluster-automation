#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}
echo "127.0.1.1 ${hostname}.kubernetes.local ${hostname}" >> /etc/hosts

# Enable root SSH access (required for the tutorial)
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Install required packages
apt-get install -y wget curl vim openssl git

# Enable IP forwarding for worker nodes
if [[ "${hostname}" == "node-"* ]]; then
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
fi

# Signal completion
echo "User data script completed successfully" >> /var/log/user-data.log
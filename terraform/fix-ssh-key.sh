#!/bin/bash

# Quick fix script for SSH key setup issue
# Usage: ./fix-ssh-key.sh <ansible-server-ip>

if [ -z "$1" ]; then
    echo "Usage: $0 <ansible-server-ip>"
    echo "Example: $0 3.85.83.67"
    exit 1
fi

ANSIBLE_IP=$1
SSH_KEY="private-key/terraform-key"

echo "=== Fixing SSH Key Setup ==="
echo "Ansible Server IP: $ANSIBLE_IP"
echo ""

# Accept host key first
echo "Accepting host key for ansible server..."
ssh-keyscan -H "$ANSIBLE_IP" >> ~/.ssh/known_hosts 2>/dev/null

# Fix SSH key setup
echo "Fixing SSH key setup on ansible server..."
ssh -i "$SSH_KEY" ubuntu@"$ANSIBLE_IP" '
    echo "1. Creating /opt directory with proper permissions..."
    sudo mkdir -p /opt
    sudo chown ubuntu:ubuntu /opt
    sudo chmod 755 /opt
    
    echo "2. Copying SSH key to /opt..."
    sudo cp ~/terraform-key /opt/terraform-key
    sudo chown ubuntu:ubuntu /opt/terraform-key
    sudo chmod 400 /opt/terraform-key
    
    echo "3. Verifying setup..."
    echo "Directory permissions:"
    ls -ld /opt
    echo ""
    echo "SSH key permissions:"
    ls -la /opt/terraform-key
    echo ""
    echo "SSH key content (first few lines):"
    head -3 /opt/terraform-key
'

echo ""
echo "=== SSH Key Fix Completed ==="
echo "You can now run the test script to verify:"
echo "./test-ansible-setup.sh $ANSIBLE_IP"

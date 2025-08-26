#!/bin/bash

# Test script to debug Ansible setup issues
# Usage: ./test-ansible-setup.sh <ansible-server-ip>

if [ -z "$1" ]; then
    echo "Usage: $0 <ansible-server-ip>"
    echo "Example: $0 34.201.171.29"
    exit 1
fi

ANSIBLE_IP=$1
SSH_KEY="private-key/terraform-key"

echo "=== Testing Ansible Setup ==="
echo "Ansible Server IP: $ANSIBLE_IP"
echo "SSH Key: $SSH_KEY"
echo ""

# Test 1: Check if SSH key exists
echo "1. Checking SSH key..."
if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH key not found at $SSH_KEY"
    exit 1
else
    echo "✓ SSH key found"
fi

# Test 2: Check SSH key permissions
echo "2. Checking SSH key permissions..."
PERMS=$(stat -c %a "$SSH_KEY")
if [ "$PERMS" != "400" ]; then
    echo "WARNING: SSH key permissions are $PERMS (should be 400)"
    echo "Fixing permissions..."
    chmod 400 "$SSH_KEY"
else
    echo "✓ SSH key permissions are correct"
fi

# Test 3: Test SSH connectivity
echo "3. Testing SSH connectivity..."
if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@"$ANSIBLE_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✓ SSH connection successful"
else
    echo "ERROR: SSH connection failed"
    echo "Please check:"
    echo "  - Instance is running"
    echo "  - Security group allows SSH (port 22)"
    echo "  - SSH key is correct"
    exit 1
fi

# Test 4: Check if Ansible is installed
echo "4. Checking Ansible installation..."
if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$ANSIBLE_IP" "which ansible" 2>/dev/null; then
    echo "✓ Ansible is installed"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$ANSIBLE_IP" "ansible --version"
else
    echo "ERROR: Ansible is not installed"
    echo "Attempting to install Ansible..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$ANSIBLE_IP" '
        sudo apt update -y
        sudo apt install software-properties-common -y
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt update -y
        sudo apt install ansible -y
        ansible --version
    '
fi

# Test 5: Check working directory and SSH key
echo "5. Checking working directory and SSH key..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$ANSIBLE_IP" '
    echo "Checking /opt directory..."
    ls -la /opt/
    echo ""
    echo "Checking SSH key in /opt..."
    if [ -f "/opt/terraform-key" ]; then
        echo "✓ SSH key found in /opt"
        ls -la /opt/terraform-key
    else
        echo "ERROR: SSH key not found in /opt"
        echo "Attempting to fix SSH key setup..."
        sudo mkdir -p /opt
        sudo chown ubuntu:ubuntu /opt
        sudo chmod 755 /opt
        sudo cp ~/terraform-key /opt/terraform-key
        sudo chown ubuntu:ubuntu /opt/terraform-key
        sudo chmod 400 /opt/terraform-key
        echo "SSH key setup attempted. Checking again..."
        ls -la /opt/terraform-key
    fi
'

# Test 6: Check inventory file
echo "6. Checking Ansible inventory..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$ANSIBLE_IP" '
    echo "Checking inventory file..."
    if [ -f "/opt/hosts" ]; then
        echo "✓ Inventory file found"
        cat /opt/hosts
    else
        echo "ERROR: Inventory file not found"
    fi
'

echo ""
echo "=== Test completed ==="

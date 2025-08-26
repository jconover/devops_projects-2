# DevOps Infrastructure with Terraform and Ansible Integration

This project demonstrates a complete DevOps infrastructure setup using Terraform to provision AWS resources and automatically configure Ansible for infrastructure management.

## Architecture

The infrastructure consists of 3 EC2 instances:
- **ansible**: Management server with Ansible installed and configured
- **jenkins-master**: Jenkins master server
- **jenkins-slave**: Jenkins slave/agent server

## Features

### ✅ Terraform Automation
- VPC with public subnets across 2 availability zones
- Security groups with SSH and Jenkins access
- EC2 instances with Ubuntu 24.04 LTS
- Automatic SSH key management

### ✅ Ansible Integration
- **Automatic Ansible Installation**: Installed on the ansible server during Terraform deployment
- **Dynamic Inventory**: Automatically generated with correct private IPs
- **SSH Key Setup**: Properly configured with correct permissions
- **Connection Testing**: Validates Ansible connectivity to all hosts

## Quick Start

### Prerequisites
- Terraform installed
- AWS CLI configured
- SSH key pair in `terraform/private-key/`

### Deployment

1. **Navigate to Terraform directory**:
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the infrastructure**:
   ```bash
   terraform apply
   ```

### What Happens During Deployment

1. **Infrastructure Creation**: Terraform creates VPC, subnets, security groups, and 3 EC2 instances
2. **Ansible Setup**: After instances are ready, Terraform automatically:
   - Installs Ansible on the ansible server
   - Creates `/opt` working directory
   - Copies and configures SSH keys
   - Generates inventory file with correct IPs
   - Updates Ansible configuration
   - Tests connectivity to all hosts

## Post-Deployment

### Access Information
After successful deployment, Terraform will output:
- Public IPs of all servers
- SSH connection commands
- Ansible inventory content
- Connection information

### Using Ansible

1. **Connect to Ansible server**:
   ```bash
   ssh -i private-key/terraform-key ubuntu@<ansible-server-ip>
   ```

2. **Test connectivity**:
   ```bash
   ansible -i /opt/hosts all -m ping
   ```

3. **Run commands on specific hosts**:
   ```bash
   # On Jenkins master
   ansible -i /opt/hosts jenkins-master -m shell -a 'hostname'
   
   # On Jenkins slave
   ansible -i /opt/hosts jenkins-slave -m shell -a 'hostname'
   ```

### Inventory Structure
The automatically generated inventory file (`/opt/hosts`) contains:
```
[jenkins-master]
<private-ip>

[jenkins-master:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key

[jenkins-slave]
<private-ip>

[jenkins-slave:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key
```

## Benefits of This Integration

1. **Single Command Deployment**: Everything is set up with one `terraform apply`
2. **Dynamic IP Management**: No manual IP updates needed
3. **Consistent Configuration**: Standardized setup across all environments
4. **Immediate Usability**: Ansible is ready to use immediately after deployment
5. **Infrastructure as Code**: Complete setup is version controlled and reproducible

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Files Structure

```
├── terraform/
│   ├── main.tf              # Main Terraform configuration with Ansible automation
│   ├── outputs.tf           # Outputs including Ansible information
│   ├── variables.tf         # Variable definitions
│   ├── terraform.tfvars     # Variable values
│   └── private-key/         # SSH keys
├── ansible/
│   └── README.md            # Original manual setup instructions
└── README.md                # This file
```

## Troubleshooting

### SSH Connection Issues
- Ensure SSH key permissions are correct: `chmod 400 private-key/terraform-key`
- Check security group allows SSH access
- Verify instances are fully booted before running Ansible setup

### Ansible Installation Issues
If Ansible isn't getting installed, try these steps:

1. **Use the test script** to debug the setup:
   ```bash
   cd terraform
   ./test-ansible-setup.sh <ansible-server-ip>
   ```

2. **Fix SSH key setup** if you see "Permission denied" errors:
   ```bash
   cd terraform
   ./fix-ssh-key.sh <ansible-server-ip>
   ```

3. **Manual installation** if the automated setup fails:
   ```bash
   # Connect to ansible server
   ssh -i private-key/terraform-key ubuntu@<ansible-server-ip>
   
   # Install Ansible manually
   sudo apt update -y
   sudo apt install software-properties-common -y
   sudo add-apt-repository --yes --update ppa:ansible/ansible
   sudo apt update -y
   sudo apt install ansible -y
   ```

4. **Check common issues**:
   - SSH key permissions (should be 400)
   - Instance fully booted (wait 2-3 minutes after creation)
   - Security group allows SSH access
   - Network connectivity between instances
   - `/opt` directory permissions (should be 755, owned by ubuntu)

### Ansible Connection Issues
- Verify SSH key is properly copied to `/opt/terraform-key` on ansible server
- Check inventory file contains correct private IPs
- Ensure all instances are in the same VPC for private IP communication

## Next Steps

With this foundation, you can now:
1. Create Ansible playbooks for Jenkins installation
2. Set up CI/CD pipelines
3. Configure monitoring and logging
4. Implement backup strategies
5. Add more infrastructure components

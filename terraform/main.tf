# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Data source for latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "demo_public-subnet-01" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = var.public_subnet_cidr-01
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-01"
  }
}

# Public Subnet
resource "aws_subnet" "demo_public-subnet-02" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = var.public_subnet_cidr-02
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-02"
  }
}

# Route Table
resource "aws_route_table" "demo_public-rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "demo_rta_public-subnet-01" {
  subnet_id      = aws_subnet.demo_public-subnet-01.id
  route_table_id = aws_route_table.demo_public-rt.id
}

resource "aws_route_table_association" "demo_rta_public-subnet-02" {
  subnet_id      = aws_subnet.demo_public-subnet-02.id
  route_table_id = aws_route_table.demo_public-rt.id
}

# Security Group - SSH only
resource "aws_security_group" "demo_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = aws_vpc.demo_vpc.id

  # SSH access only
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins Port
  ingress {
    description = "Jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# Key Pair
resource "aws_key_pair" "demo_deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

# EC2 Instance - Ubuntu 24.04 LTS
resource "aws_instance" "demo-server" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.demo_deployer.key_name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  subnet_id              = aws_subnet.demo_public-subnet-01.id
  for_each               = toset(["jenkins-master", "jenkins-slave", "ansible"])

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt upgrade -y
              echo "Ubuntu 24.04 LTS instance is ready!"
              EOF

  tags = {
    Name = "${each.key}"
  }
}

# Ansible Setup Automation
resource "null_resource" "ansible_setup" {
  depends_on = [aws_instance.demo-server]

  # Wait for instances to be fully ready
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instances to be fully ready..."
      sleep 30
      echo "Instances should be ready now"
    EOT
  }

  # Step 1: Copy SSH key to ansible server first
  provisioner "local-exec" {
    command = <<-EOT
      echo "Copying SSH key to ansible server..."
      scp -i private-key/terraform-key -o StrictHostKeyChecking=no private-key/terraform-key ubuntu@${aws_instance.demo-server["ansible"].public_ip}:~/terraform-key
      echo "SSH key copied successfully"
    EOT
  }

  # Step 2: Install Ansible on the ansible server
  provisioner "local-exec" {
    command = <<-EOT
      echo "Installing Ansible on ansible server..."
      ssh -i private-key/terraform-key -o StrictHostKeyChecking=no ubuntu@${aws_instance.demo-server["ansible"].public_ip} '
        echo "Starting Ansible installation..."
        sudo apt update -y
        echo "System updated"
        sudo apt install software-properties-common -y
        echo "Software properties installed"
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        echo "Ansible repository added"
        sudo apt update -y
        echo "Updated package list with Ansible repository"
        sudo apt install ansible -y
        echo "Ansible installation completed"
        ansible --version
      '
    EOT
  }

  # Step 3: Create working directory and setup SSH key
  provisioner "local-exec" {
    command = <<-EOT
      echo "Setting up working directory and SSH key..."
      ssh -i private-key/terraform-key -o StrictHostKeyChecking=no ubuntu@${aws_instance.demo-server["ansible"].public_ip} '
        sudo mkdir -p /opt
        sudo chown ubuntu:ubuntu /opt
        cp ~/terraform-key /opt/terraform-key
        chmod 400 /opt/terraform-key
        echo "Working directory and SSH key setup completed"
      '
    EOT
  }

  # Step 4: Create Ansible inventory file
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Ansible inventory file..."
      ssh -i private-key/terraform-key -o StrictHostKeyChecking=no ubuntu@${aws_instance.demo-server["ansible"].public_ip} '
        cat > /opt/hosts << EOF
[jenkins-master]
${aws_instance.demo-server["jenkins-master"].private_ip}

[jenkins-master:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key

[jenkins-slave]
${aws_instance.demo-server["jenkins-slave"].private_ip}

[jenkins-slave:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key
EOF
        echo "Ansible inventory file created"
      '
    EOT
  }

  # Step 5: Configure Ansible to use custom inventory
  provisioner "local-exec" {
    command = <<-EOT
      echo "Configuring Ansible to use custom inventory..."
      ssh -i private-key/terraform-key -o StrictHostKeyChecking=no ubuntu@${aws_instance.demo-server["ansible"].public_ip} '
        sudo cp /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.backup
        sudo sed -i "s|inventory = /etc/ansible/hosts|inventory = /opt/hosts|" /etc/ansible/ansible.cfg
        echo "Ansible configuration updated"
      '
    EOT
  }

  # Step 6: Test Ansible connection
  provisioner "local-exec" {
    command = <<-EOT
      echo "Testing Ansible connection to all hosts..."
      ssh -i private-key/terraform-key -o StrictHostKeyChecking=no ubuntu@${aws_instance.demo-server["ansible"].public_ip} '
        ansible -i /opt/hosts all -m ping
      '
    EOT
  }

  # Step 7: Display connection information
  provisioner "local-exec" {
    command = <<-EOT
      echo "=== ANSIBLE SETUP COMPLETED ==="
      echo "Ansible Server IP: ${aws_instance.demo-server["ansible"].public_ip}"
      echo "Jenkins Master IP: ${aws_instance.demo-server["jenkins-master"].public_ip}"
      echo "Jenkins Slave IP: ${aws_instance.demo-server["jenkins-slave"].public_ip}"
      echo ""
      echo "To connect to Ansible server:"
      echo "ssh -i private-key/terraform-key ubuntu@${aws_instance.demo-server["ansible"].public_ip}"
      echo ""
      echo "To run Ansible commands from Ansible server:"
      echo "ansible -i /opt/hosts all -m ping"
      echo "ansible -i /opt/hosts jenkins-master -m shell -a 'hostname'"
      echo "ansible -i /opt/hosts jenkins-slave -m shell -a 'hostname'"
    EOT
  }
}

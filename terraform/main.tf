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

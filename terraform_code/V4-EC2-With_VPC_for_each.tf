# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5"
    }
  }
}

provider "aws" {
  region = "us-east-2" # Change to your preferred region
}

# Create VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "demo_vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_igw"
  }
}

# Create public subnet
resource "aws_subnet" "demo_public_subnet-01" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a" # Change to match your region
  map_public_ip_on_launch = true

  tags = {
    Name = "demo_public_subnet-01"
  }
}

# Create public subnet
resource "aws_subnet" "demo_public_subnet-02" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b" # Change to match your region
  map_public_ip_on_launch = true

  tags = {
    Name = "demo_public_subnet-02"
  }
}


# Create route table
resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "demo_public_rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "demo_public_rta-01" {
  subnet_id      = aws_subnet.demo_public_subnet-01.id
  route_table_id = aws_route_table.demo_public_rt.id
}

resource "aws_route_table_association" "demo_public_rta-02" {
  subnet_id      = aws_subnet.demo_public_subnet-02.id
  route_table_id = aws_route_table.demo_public_rt.id
}

# Create Security Group
resource "aws_security_group" "demo_sg" {
  name        = "demo_sg"
  description = "Security group for demo EC2 instance"
  vpc_id      = aws_vpc.demo_vpc.id

  # SSH access on port 22
  ingress {
    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for better security
  }

   # Jenkins access on port 8080
  ingress {
    description = "Jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for better security
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo_sg"
  }
}

# Get the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
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
}

# Get the latest Amazon Linux 2023 AMI
#data "aws_ami" "amazon_linux" {
#  most_recent = true
#  owners      = ["amazon"]
#
#  filter {
#    name   = "name"
#    values = ["al2023-ami-*-x86_64"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#}

# Create EC2 instance
resource "aws_instance" "demo_instance" {
  for_each = toset(["jenkins-master", "build-slave", "ansible"])

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "devops_projects" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  subnet_id             = aws_subnet.demo_public_subnet-01.id
  
  tags = {
    Name = each.key
  }
}

# Output values
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.demo_vpc.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.demo_sg.id
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = { for k, v in aws_instance.demo_instance : k => v.id }
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = { for k, v in aws_instance.demo_instance : k => v.public_ip }
}

output "instance_public_dns" {
  description = "Public DNS names of the EC2 instances"
  value       = { for k, v in aws_instance.demo_instance : k => v.public_dns }
}
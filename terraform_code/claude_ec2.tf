# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
resource "aws_subnet" "demo_public_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a" # Change to match your region
  map_public_ip_on_launch = true

  tags = {
    Name = "demo_public_subnet"
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
resource "aws_route_table_association" "demo_public_rta" {
  subnet_id      = aws_subnet.demo_public_subnet.id
  route_table_id = aws_route_table.demo_public_rt.id
}

# Create Security Group
resource "aws_security_group" "demo_sg" {
  name        = "demo_sg"
  description = "Security group for demo EC2 instance"
  vpc_id      = aws_vpc.demo_vpc.id

  # SSH access on port 22
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EC2 instance
resource "aws_instance" "demo_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = "devops_projects" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  subnet_id             = aws_subnet.demo_public_subnet.id

  tags = {
    Name = "demo_instance"
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

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.demo_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.demo_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.demo_instance.public_dns
}
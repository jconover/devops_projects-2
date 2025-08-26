variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr-01" {
  description = "CIDR block for public subnet 01"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr-02" {
  description = "CIDR block for public subnet 02"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
  type        = string
  default     = ""
}

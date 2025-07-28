provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "demo-server" {
  ami           = "ami-08ca1d1e465fbfe0c"
  instance_type = "t2.micro"
  key_name = "devops_projects"
  security_groups = [aws_security_group.demo_sg.name]
}

resource "aws_security_group" "demo_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
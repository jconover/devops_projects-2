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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0/0"]
}

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0/0"]
    }

    tags = {
        Name = "demo_sg"
    }

}
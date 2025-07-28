provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "demo-server" {
  ami           = "ami-08ca1d1e465fbfe0c"
  instance_type = "t2.micro"
  key_name = "devops_projects"
}


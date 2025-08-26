output "demo_instance_ids" {
  description = "IDs of all Demo EC2 instances"
  value       = { for k, v in aws_instance.demo-server : k => v.id }
}

output "demo_instance_public_ips" {
  description = "Public IP addresses of all Demo EC2 instances"
  value       = { for k, v in aws_instance.demo-server : k => v.public_ip }
}

output "demo_instance_public_dns" {
  description = "Public DNS names of all Demo EC2 instances"
  value       = { for k, v in aws_instance.demo-server : k => v.public_dns }
}

output "demo_vpc_id" {
  description = "ID of the Demo VPC"
  value       = aws_vpc.demo_vpc.id
}

output "demo_security_group_id" {
  description = "ID of the Demo security group"
  value       = aws_security_group.demo_sg.id
}

output "demo_ssh_commands" {
  description = "SSH commands to connect to all Demo instances"
  value       = { for k, v in aws_instance.demo-server : k => "ssh -i private-key/terraform-key ubuntu@${v.public_ip}" }
}

# Individual instance outputs for easier access
output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins Master instance"
  value       = aws_instance.demo-server["jenkins-master"].public_ip
}

output "jenkins_slave_public_ip" {
  description = "Public IP of Jenkins Slave instance"
  value       = aws_instance.demo-server["jenkins-slave"].public_ip
}

output "ansible_public_ip" {
  description = "Public IP of Ansible instance"
  value       = aws_instance.demo-server["ansible"].public_ip
}

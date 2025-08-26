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

# Ansible-specific outputs
output "ansible_inventory_content" {
  description = "Content of the Ansible inventory file"
  value       = <<-EOT
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
EOT
}

output "ansible_connection_info" {
  description = "Connection information for Ansible setup"
  value = {
    ansible_server_ip = aws_instance.demo-server["ansible"].public_ip
    jenkins_master_ip = aws_instance.demo-server["jenkins-master"].public_ip
    jenkins_slave_ip  = aws_instance.demo-server["jenkins-slave"].public_ip
    ssh_command       = "ssh -i private-key/terraform-key ubuntu@${aws_instance.demo-server["ansible"].public_ip}"
    ansible_test_cmd  = "ansible -i /opt/hosts all -m ping"
  }
}

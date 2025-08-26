
# Setup Ansible
1. Install ansibe on the designated Ansible server running Ubuntu 24.04 
   ```sh 
   sudo apt update
   sudo apt install software-properties-common
   sudo add-apt-repository --yes --update ppa:ansible/ansible
   sudo apt install ansible
   ```

2. Add Jenkins master and slave as hosts
Add jenkins master and slave private IPs in the inventory file
in this case, we are using /opt is our working directory for Ansible.

You can move your hosts file by changing the location in /etc/ansible/ansible.cfg

```
vi /etc/ansible/ansible.cfg

[defaults]
inventory = /opt/hosts
```

   ```
[jenkins-master]
10.0.1.33

[jenkins-master:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key

[jenkins-slave]
10.0.1.188

[jenkins-slave:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/terraform-key
   ```
3. Copy over your private_key to all 3 servers:

 **Note** I was using my Windows workstation for this and to change the permissions of your private key. I used WSL. You have to copy the key over to your home directory in order to change the permissions to 400.

 e.g.: 

 ```
 cp private-key/terraform-key C:\Users\<you>\
 bash
 cd ~/
 chmod 400 terraform-key
  scp -i terraform-key terraform-key ubuntu@34.201.171.29:~/
terraform-key
```

After logging into you your server, copy the key to /opt

1. Test the connection  
   ```sh
   ansible -i /opt/hosts all -m ping 
   ```

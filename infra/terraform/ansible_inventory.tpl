web-server ansible_host=${webserver_ip} ansible_user=${ssh_user} ansible_ssh_common_args='-o StrictHostKeyChecking=no' repository=https://github.com/Big-Vi/wagtail-ansible-terraform.git
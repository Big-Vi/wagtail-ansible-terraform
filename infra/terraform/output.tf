# Webserver IP Address
output "webserver_ip" {
  value = aws_instance.webserver.public_ip
}

# Process Ansible inventory template
data "template_file" "ansible_inventory" {
  template = file("ansible_inventory.tpl")
  vars = {
    webserver_ip = aws_instance.webserver.public_ip
    ssh_user     = var.ssh_user_name
  }
}

# Generate inventory file
resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "../terraform/output/inventory"
}

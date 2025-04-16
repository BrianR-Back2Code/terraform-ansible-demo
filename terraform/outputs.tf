# Output: Öffentliche IP-Adresse des Webservers
output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}

# Output: Instance-ID
output "instance_id" {
  value = aws_instance.web_server.id
}

# Output: Ansible-Inventory im JSON-Format
output "ansible_inventory" {
  value = {
    webservers = {
      hosts = {
        web = {
          ansible_host = aws_instance.web_server.public_ip
          ansible_user = "ec2-user"
          ansible_ssh_private_key_file = var.private_key_path
        }
      }
    }
  }
}
# Private Key Path
output "private_key_path" {
  value = var.private_key_path
}

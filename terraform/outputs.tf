output "jumpbox_public_ip" {
  description = "Public IP address of the jumpbox"
  value       = aws_instance.jumpbox.public_ip
}

output "server_private_ip" {
  description = "Private IP address of the server"
  value       = aws_instance.server.private_ip
}

output "node_0_private_ip" {
  description = "Private IP address of node-0"
  value       = aws_instance.node_0.private_ip
}

output "node_1_private_ip" {
  description = "Private IP address of node-1"
  value       = aws_instance.node_1.private_ip
}

output "ansible_inventory" {
  description = "Ansible inventory in INI format"
  value = templatefile("${path.module}/templates/inventory.tpl", {
    jumpbox_public_ip  = aws_instance.jumpbox.public_ip
    server_private_ip  = aws_instance.server.private_ip
    node_0_private_ip  = aws_instance.node_0.private_ip
    node_1_private_ip  = aws_instance.node_1.private_ip
    pod_cidr_node_0    = var.pod_cidr_blocks[0]
    pod_cidr_node_1    = var.pod_cidr_blocks[1]
  })
}

output "machines_txt" {
  description = "machines.txt content for manual setup"
  value = templatefile("${path.module}/templates/machines.tpl", {
    server_private_ip = aws_instance.server.private_ip
    node_0_private_ip = aws_instance.node_0.private_ip
    node_1_private_ip = aws_instance.node_1.private_ip
    pod_cidr_node_0   = var.pod_cidr_blocks[0]
    pod_cidr_node_1   = var.pod_cidr_blocks[1]
  })
}

output "key_name" {
  description = "AWS key pair name used"
  value       = local.key_name
}
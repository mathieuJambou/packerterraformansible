

# IDs of virtual networks provisioned.
output "vm_ids" {
  description = "IDs of virtual networks provisioned."
  value       = concat(azurerm_virtual_machine.bastion_vm.*.id, azurerm_virtual_machine.worker_vm.*.id)
}

# IDs of subnets provisioned.
output "network_subnet_ids" {
  description = "IDs of subnets provisioned."
  value       = concat(azurerm_subnet.public_subnet.*.id, azurerm_subnet.private_subnet.*.id)
}

# Prefixes of virtual networks provisioned.
output "network_subnet_prefixes" {
  description = "Prefixes of virtual networks provisioned."
  value       = concat(azurerm_subnet.public_subnet.*.address_prefix, azurerm_subnet.private_subnet.*.address_prefix)
}

# IDs of network security groups provisioned.
output "network_security_group_ids" {
  description = "IDs of network security groups provisioned."
  value       = concat(azurerm_network_security_group.public_nsg.*.id, azurerm_network_security_group.private_nsg.*.id)
}

# IDs of network interfaces provisioned.
output "network_interface_ids" {
  description = "IDs of network interfaces provisioned."
  value       = concat(azurerm_network_interface.bastion_nic.*.id, azurerm_network_interface.worker_nic.*.id)
}

# IDs of public IP addresses provisioned.
output "public_ip_ids" {
  description = "IDs of public IP addresses provisioned."
  value       = azurerm_public_ip.public_ip.*.id
}

# IP addresses of public IP addresses provisioned.
output "public_ip_addresses" {
  description = "IP addresses of public IP addresses provisioned."
  value       = azurerm_public_ip.public_ip.*.ip_address
}

# FQDNs of public IP addresses provisioned.
output "public_ip_dns_names" {
  description = "FQDNs of public IP addresses provisioned."
  value       = azurerm_public_ip.public_ip.*.fqdn
}

# IP addresses of private IP addresses provisioned.
output "private_ip_addresses" {
  description = "IP addresses of private IP addresses provisioned."
  value       = concat(azurerm_network_interface.bastion_nic.*.private_ip_address, azurerm_network_interface.worker_nic.*.private_ip_address)
}


output "tls_bastion_private_key" { 
  value = tls_private_key.bastion_ssh.private_key_pem 
}


output "tls_worker_private_key" { 
  value = tls_private_key.worker_ssh.private_key_pem 
}

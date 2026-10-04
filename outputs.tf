# ============================================================
# Summit Ridge Engineering — Terraform Outputs
# ============================================================

output "resource_group_name" {
  description = "Lab resource group being used"
  value       = data.azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Region confirmed by the lab RG"
  value       = data.azurerm_resource_group.rg.location
}

output "vnet_id" {
  description = "Virtual Network resource ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vpn_gateway_public_ip" {
  description = "Azure VPN Gateway public IP — copy this into the edge router VPN config and terraform.tfvars onprem_public_ip after GNS3 is up"
  value       = azurerm_public_ip.vpn_gw_pip.ip_address
}

output "jump_host_public_ip" {
  description = "Jump Host public IP — SSH in before the VPN tunnel is established"
  value       = azurerm_public_ip.jump_host_pip.ip_address
}

output "jump_host_private_ip" {
  description = "Jump Host private IP (static 10.1.3.10)"
  value       = azurerm_network_interface.jump_host_nic.private_ip_address
}

output "workload_vm_private_ip" {
  description = "Workload VM private IP (dynamic from 10.1.1.0/24)"
  value       = azurerm_network_interface.workload_nic.private_ip_address
}

output "ssh_command_jump_host" {
  description = "SSH command to connect to Jump Host"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.jump_host_pip.ip_address}"
}

output "workload_nsg_id" {
  description = "Workload NSG resource ID"
  value       = azurerm_network_security_group.workload_nsg.id
}

output "data_nsg_id" {
  description = "Data NSG resource ID"
  value       = azurerm_network_security_group.data_nsg.id
}

output "mgmt_nsg_id" {
  description = "Management NSG resource ID"
  value       = azurerm_network_security_group.mgmt_nsg.id
}

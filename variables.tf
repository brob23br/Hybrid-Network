# ============================================================
# Summit Ridge Engineering — Terraform Variables
# Azure Hybrid Network Capstone
# Lab constraints: RG=cal-3756-d22, Region=SouthCentralUS
# ============================================================

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# ─── VNet / Subnets ───────────────────────────────────────
variable "vnet_name" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "summit-ridge-vnet"
}

variable "vnet_address_space" {
  description = "VNet address space — must not overlap on-prem 10.0.0.0/8"
  type        = string
  default     = "10.1.0.0/16"
}

variable "workload_subnet_prefix" {
  description = "Workload subnet (VLAN 10 equivalent in Azure)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "data_subnet_prefix" {
  description = "Data subnet (VLAN 20 equivalent in Azure)"
  type        = string
  default     = "10.1.2.0/24"
}

variable "mgmt_subnet_prefix" {
  description = "Management subnet — Jump Host lives here"
  type        = string
  default     = "10.1.3.0/24"
}

variable "gateway_subnet_prefix" {
  description = "GatewaySubnet — required name/prefix for VPN Gateway"
  type        = string
  default     = "10.1.255.0/27"
}

# ─── VPN / IPsec ──────────────────────────────────────────
variable "onprem_public_ip" {
  description = "Public IP of the on-prem edge router WAN interface — update after GNS3 boots"
  type        = string
}

variable "onprem_address_space" {
  description = "On-prem LAN prefix — used in VPN local network gateway"
  type        = string
  default     = "10.0.0.0/8"
}

variable "vpn_shared_key" {
  description = "Pre-shared key for the IPsec VPN tunnel (minimum 16 chars)"
  type        = string
  sensitive   = true
}

# ─── VM credentials ───────────────────────────────────────
variable "admin_username" {
  description = "Admin username for all Azure VMs"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for all Azure VMs (min 12 chars, mixed case + digit + special)"
  type        = string
  sensitive   = true
}

variable "os_disk_sku" {
  description = "OS disk SKU"
  type        = string
  default     = "Standard_LRS"
}

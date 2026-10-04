# ============================================================
# Summit Ridge Engineering — Azure Hybrid Network
# Terraform Main Configuration
# Lab constraints: RG=cal-3756-d22, Region=SouthCentralUS,
#                  VM SKU=Standard_B1s, VPN GW SKU=VpnGw1AZ
# Provider: hashicorp/azurerm ~> 3.0
# ============================================================

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ─────────────────────────────────────────────────────────
# RESOURCE GROUP — pre-existing lab RG (data source only)
# Do NOT create a new resource group. The lab environment
# provides cal-3756-d22; Terraform will reference it here.
# ─────────────────────────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "cal-3756-d22"
}

# ─────────────────────────────────────────────────────────
# VIRTUAL NETWORK
# ─────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
  tags = {
    Project = "SummitRidge-Capstone"
  }
}

# ─────────────────────────────────────────────────────────
# SUBNETS
# ─────────────────────────────────────────────────────────
resource "azurerm_subnet" "workload" {
  name                 = "Workload-Subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.workload_subnet_prefix]
}

resource "azurerm_subnet" "data" {
  name                 = "Data-Subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.data_subnet_prefix]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "Management-Subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.mgmt_subnet_prefix]
}

# GatewaySubnet — name must be exactly "GatewaySubnet" per Azure requirement.
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

# ─────────────────────────────────────────────────────────
# NETWORK SECURITY GROUPS
# ─────────────────────────────────────────────────────────

# — Workload-NSG —
resource "azurerm_network_security_group" "workload_nsg" {
  name                = "Workload-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-from-Mgmt"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.mgmt_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP-from-OnPrem"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.onprem_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload_nsg_assoc" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload_nsg.id
}

# — Data-NSG —
resource "azurerm_network_security_group" "data_nsg" {
  name                = "Data-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-All-from-Workload"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.workload_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-from-Mgmt"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.mgmt_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-from-OnPrem"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.onprem_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_assoc" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

# — Management-NSG —
resource "azurerm_network_security_group" "mgmt_nsg" {
  name                = "Mgmt-NSG"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-from-OnPrem-Servers"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.30.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP-from-OnPrem-Eng"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.10.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-from-Workload"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.workload_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_assoc" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

# ─────────────────────────────────────────────────────────
# PUBLIC IPs
# VpnGw1AZ requires a zone-redundant Standard static public IP.
# ─────────────────────────────────────────────────────────
resource "azurerm_public_ip" "vpn_gw_pip" {
  name                = "summit-ridge-vpn-gw-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]   # Required for VpnGw1AZ
}

resource "azurerm_public_ip" "jump_host_pip" {
  name                = "summit-ridge-jump-host-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ─────────────────────────────────────────────────────────
# VPN GATEWAY — SKU: VpnGw1AZ (lab requirement)
# VpnGw1AZ is zone-redundant and requires SouthCentralUS.
# Provisioning takes ~30-45 minutes — do not cancel apply.
# ─────────────────────────────────────────────────────────
resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = "summit-ridge-vpn-gw"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vpn-gw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

# ─────────────────────────────────────────────────────────
# LOCAL NETWORK GATEWAY (represents on-prem edge router)
# ─────────────────────────────────────────────────────────
resource "azurerm_local_network_gateway" "onprem" {
  name                = "summit-ridge-onprem-lng"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  gateway_address     = var.onprem_public_ip
  address_space       = [var.onprem_address_space]
}

# ─────────────────────────────────────────────────────────
# VPN CONNECTION (Site-to-Site IPsec/IKEv2)
# ─────────────────────────────────────────────────────────
resource "azurerm_virtual_network_gateway_connection" "s2s" {
  name                       = "summit-ridge-s2s-connection"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem.id
  shared_key                 = var.vpn_shared_key

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_lifetime      = 28800
    sa_datasize      = 102400000
  }
}

# ─────────────────────────────────────────────────────────
# NETWORK INTERFACES
# ─────────────────────────────────────────────────────────
resource "azurerm_network_interface" "workload_nic" {
  name                = "workload-vm-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "workload-ip-config"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "jump_host_nic" {
  name                = "jump-host-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "jump-host-ip-config"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.3.10"
    public_ip_address_id          = azurerm_public_ip.jump_host_pip.id
  }
}

# ─────────────────────────────────────────────────────────
# VIRTUAL MACHINES — SKU: Standard_B1s (lab requirement)
# ─────────────────────────────────────────────────────────
resource "azurerm_linux_virtual_machine" "workload_vm" {
  name                            = "workload-vm"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.workload_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_sku
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Role    = "Workload"
    Project = "SummitRidge-Capstone"
  }
}

resource "azurerm_linux_virtual_machine" "jump_host" {
  name                            = "jump-host"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.jump_host_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_sku
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Role    = "JumpHost"
    Project = "SummitRidge-Capstone"
  }
}

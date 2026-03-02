data "azurerm_resource_group" "foundry" {
  name = "${var.project_name}-rg"
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_virtual_network" "foundry" {
  name                = "${var.project_name}-vnet"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.foundry.location
  resource_group_name = data.azurerm_resource_group.foundry.name
  tags                = var.tags
}

resource "azurerm_subnet" "foundry" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = data.azurerm_resource_group.foundry.name
  virtual_network_name = azurerm_virtual_network.foundry.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_public_ip" "foundry" {
  name                = "${var.project_name}-pip"
  location            = data.azurerm_resource_group.foundry.location
  resource_group_name = data.azurerm_resource_group.foundry.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_security_group" "foundry" {
  name                = "${var.project_name}-nsg"
  location            = data.azurerm_resource_group.foundry.location
  resource_group_name = data.azurerm_resource_group.foundry.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_ips
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.foundry.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "AllowHTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.foundry.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "AllowHTTPS"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.foundry.name
  network_security_group_name = azurerm_network_security_group.foundry.name
}

# Commented out: Port 30000 no longer needed (Caddy handles HTTPS on 443)
# resource "azurerm_network_security_rule" "foundry" {
#   name                        = "AllowFoundryVTT"
#   priority                    = 130
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = tostring(var.foundry_port)
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = data.azurerm_resource_group.foundry.name
#   network_security_group_name = azurerm_network_security_group.foundry.name
# }

resource "azurerm_network_interface" "foundry" {
  name                = "${var.project_name}-nic"
  location            = data.azurerm_resource_group.foundry.location
  resource_group_name = data.azurerm_resource_group.foundry.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.foundry.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.foundry.id
  }
}

resource "azurerm_network_interface_security_group_association" "foundry" {
  network_interface_id      = azurerm_network_interface.foundry.id
  network_security_group_id = azurerm_network_security_group.foundry.id
}

resource "azurerm_storage_account" "foundry" {
  name                     = var.storage_account_name != "" ? var.storage_account_name : "${var.project_name}st${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.foundry.name
  location                 = data.azurerm_resource_group.foundry.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_share" "foundry" {
  name                 = "foundrydata"
  storage_account_name = azurerm_storage_account.foundry.name
  quota                = var.fileshare_quota_gb
}

resource "azurerm_linux_virtual_machine" "foundry" {
  name                = "${var.project_name}-vm"
  resource_group_name = data.azurerm_resource_group.foundry.name
  location            = data.azurerm_resource_group.foundry.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.foundry.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = <<-EOT
[foundry]
${azurerm_public_ip.foundry.ip_address} ansible_user=${var.vm_admin_username} ansible_ssh_private_key_file=/root/.ssh/foundry_azure

[foundry:vars]
azure_storage_account=${azurerm_storage_account.foundry.name}
azure_fileshare_name=${azurerm_storage_share.foundry.name}
foundry_domain=${var.foundry_domain}
EOT

  file_permission = "0644"
}

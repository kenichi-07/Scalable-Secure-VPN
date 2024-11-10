# Provider Configuration
provider "azurerm" {
  features {}
  subscription_id = "bc86d3cb-dbde-4f24-be16-a3593c25ba9a"
}

# Resource Group
resource "azurerm_resource_group" "vpn_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network and Subnet
resource "azurerm_virtual_network" "vpn_vnet" {
  name                = "vpn-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
}

resource "azurerm_subnet" "vpn_subnet" {
  name                 = "vpn-subnet"
  resource_group_name  = azurerm_resource_group.vpn_rg.name
  virtual_network_name = azurerm_virtual_network.vpn_vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# Network Security Group
resource "azurerm_network_security_group" "subnet_nsg" {
  name                = "subnet-nsg"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name

  security_rule {
    name                       = "allow-vpn-traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"  # OpenVPN port
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"  # SSH access
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

# Public IP for the VM
resource "azurerm_public_ip" "vpn_public_ip" {
  name                = "vpn-public-ip"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  allocation_method   = "Static"
}

# Network Interface with Public IP attached
resource "azurerm_network_interface" "vpn_nic" {
  name                = "vpn-nic"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vpn_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn_public_ip.id
  }
}

# Virtual Machine Configuration with SSH Key
resource "azurerm_virtual_machine" "vpn_vm" {
  name                  = "vpn-server-vm"
  location              = azurerm_resource_group.vpn_rg.location
  resource_group_name   = azurerm_resource_group.vpn_rg.name
  network_interface_ids = [azurerm_network_interface.vpn_nic.id]
  vm_size               = "Standard_B1ms"  # Economical choice for VPN server

  storage_os_disk {
    name              = "vpn-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vpn-server-vm"
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    # Corrected ssh_keys block
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = var.ssh_public_key
    }
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vpn_subnet.id
  network_security_group_id = azurerm_network_security_group.subnet_nsg.id
}

# OpenVPN Installation with Custom Script Extension
resource "azurerm_virtual_machine_extension" "vpn_install" {
  name                 = "vpn-install"
  virtual_machine_id   = azurerm_virtual_machine.vpn_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update && sudo apt-get install -y openvpn && wget https://git.io/vpn -O openvpn-install.sh && sudo bash openvpn-install.sh"
    }
  SETTINGS
}
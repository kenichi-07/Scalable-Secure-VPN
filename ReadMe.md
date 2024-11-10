# Scalable and Secure VPN on Azure Cloud

## Overview

This project sets up a secure and scalable VPN hosted on Azure using OpenVPN, with a cybersecurity-first approach to ensure data security and controlled access. The VPN configuration employs Terraform for Infrastructure as Code (IaC), automates configuration updates, and sets up real-time monitoring and anomaly detection.

## Project Objectives

1. **Cybersecurity-Focused Design**: Implement encryption, network isolation, and authentication controls to ensure secure VPN operations.
2. **Scalable Security Architecture**: Enable dynamic scaling for additional users or devices.
3. **Automated Security Management**: Use IaC with Terraform and CI/CD pipelines to ensure consistent security configurations and updates.
4. **Continuous Monitoring and Threat Detection**: Deploy real-time monitoring systems to detect and respond to security threats.

## Architecture Diagram

Refer to the provided architecture diagram (attached as `architecture_diagram.png`), which illustrates the overall setup from the Azure resource group to the VPN virtual machine (VM).

## Prerequisites

- Azure account
- Terraform installed locally
- OpenVPN installed on the client machine for testing
- GitHub repository for managing CI/CD pipeline with GitHub Actions

## Project Files

- `main.tf`: Defines Azure resources such as the virtual network, subnet, and VM.
- `variables.tf`: Contains configurable variables.
- `terraform.tfvars`: Stores values for variables in `variables.tf`.
- `outputs.tf`: Specifies outputs to display after applying Terraform.
- `client1.ovpn`, `client1.crt`, `client1.key`, `ca.crt`: Client configuration files and certificates.
- `Project Proposal.pdf`: Document outlining project goals, phases, and methodology.

## Step-by-Step Setup

### Step 1: Azure Provider Configuration

In `main.tf`, configure the Azure provider:

```hcl
provider "azurerm" {
  features {}
}
```

### Step 2: Resource Group Setup

Define the resource group to house all Azure resources:

```hcl
resource "azurerm_resource_group" "vpn_rg" {
  name     = "vpn_rg"
  location = "East US"
}
```

### Step 3: Virtual Network and Subnet Configuration

Set up a virtual network and subnet:

```hcl
resource "azurerm_virtual_network" "vpn_vnet" {
  name                = "vpn_vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.vpn_rg.name
  location            = azurerm_resource_group.vpn_rg.location
}

resource "azurerm_subnet" "vpn_subnet" {
  name                 = "vpn_subnet"
  resource_group_name  = azurerm_resource_group.vpn_rg.name
  virtual_network_name = azurerm_virtual_network.vpn_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

### Step 4: Network Security Groups (NSGs)

Define NSGs for the subnet and VM to restrict access:

```hcl
resource "azurerm_network_security_group" "subnet_nsg" {
  name                = "subnet_nsg"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
}
```

Add specific rules to allow OpenVPN traffic (port 1194).

### Step 5: Public IP Address and Network Interface

Provision a public IP and link it to a network interface:

```hcl
resource "azurerm_public_ip" "vpn_public_ip" {
  name                = "vpn_public_ip"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vpn_nic" {
  name                = "vpn_nic"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vpn_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn_public_ip.id
  }
}
```

### Step 6: Virtual Machine for OpenVPN Server

Provision a VM with Ubuntu OS for hosting OpenVPN:

```hcl
resource "azurerm_linux_virtual_machine" "vpn_vm" {
  name                = "vpn_vm"
  location            = azurerm_resource_group.vpn_rg.location
  resource_group_name = azurerm_resource_group.vpn_rg.name
  size                = "Standard_B1s"

  admin_username      = "vpn-vm-admin"
  admin_password      = "SecurePassword123"  # use a secure password

  network_interface_ids = [azurerm_network_interface.vpn_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
```

### Step 7: Applying Terraform

Initialize and apply the configuration:

```bash
terraform init
terraform apply
```

### Step 8: SSH into the VM

Retrieve the public IP from the Terraform output and SSH into the VM:

```bash
ssh vpn-vm-admin@<public_ip>
```

### Step 9: Install and Configure OpenVPN

1. **Install OpenVPN**:

   ```bash
   sudo apt update
   sudo apt install -y openvpn
   ```

2. **Configure OpenVPN**:
   - Generate server and client certificates using Easy-RSA.
   - Transfer the `client1.ovpn`, `client1.crt`, `client1.key`, and `ca.crt` files to the client machine.

3. **Enable IP Forwarding**:

   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

### Step 10: OpenVPN Service Management

Start and enable the OpenVPN service:

```bash
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
```

### Step 11: Firewall and Security Rules

Check and update firewall/NSG rules to allow OpenVPN traffic:

- **UFW**:

  ```bash
  sudo ufw allow 1194/udp
  sudo ufw enable
  ```

- **Azure NSG**: Configure the NSG to allow traffic on port 1194 (UDP).

### Step 12: Client Configuration

1. Install OpenVPN on the client machine.
2. Import the `client1.ovpn` configuration file into the OpenVPN client.

### Step 13: Troubleshooting Steps

- **Common Errors**:
  - **Peer Certificate Verification Failure**: Ensure the correct certificates are in place and permissions are correctly set (`chmod 644` for `.crt` files and `chmod 600` for `.key` files).
  - **Firewall Issues**: Confirm that both the VM and Azure NSG allow traffic on port 1194.
  - **Connectivity Problems**: Use logs (`sudo journalctl -u openvpn@server -e`) for detailed error messages.

### Step 14: Continuous Monitoring and Threat Detection

1. Configure Azure Monitor and Log Analytics for VPN activity.
2. Set up alerts for unusual activity and configure anomaly detection if required.

### Step 15: Security Testing and Documentation

Conduct security testing (e.g., penetration testing) and document the entire setup and findings. Ensure compliance with NIST and ISO standards.

---

## Expected Outcomes

By following these steps, you should have a fully functional VPN on Azure that provides secure access and monitors for potential security incidents. The setup ensures scalability and compliance with industry security standards.

## Files Included

- **Terraform Configurations**: `main.tf`, `variables.tf`, `terraform.tfvars`, `outputs.tf`
- **Client Configurations**: `client1.ovpn`, `client1.crt`, `client1.key`, `ca.crt`
- **Diagrams**: `architecture_diagram.png`
- **Documentation**: `Project Proposal.pdf`

---

This README covers all aspects from the initial Terraform setup, VPN configuration, to detailed troubleshooting and monitoring steps. Follow this guide precisely to ensure a secure and scalable VPN deployment on Azure.
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "West US"
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the VNet."
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the subnet."
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM access."
}

variable "allowed_ip" {
  type        = string
  description = "IP address allowed for SSH and VPN access."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access."
}

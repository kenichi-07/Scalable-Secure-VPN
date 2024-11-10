# Outputs
output "vpn_public_ip" {
  value       = azurerm_public_ip.vpn_public_ip.ip_address
  description = "Public IP address of the VPN server."
}

output "admin_username" {
  value       = var.admin_username
  description = "Username for SSH access."
}

output "location" {
  value       = var.location
  description = "Location of the VPN server."
}
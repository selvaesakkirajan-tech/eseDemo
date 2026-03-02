output "appgw_id" {
  value       = azurerm_application_gateway.main.id
  description = "Application Gateway resource ID (used by AGIC Helm chart)"
}

output "appgw_name" {
  value       = azurerm_application_gateway.main.name
  description = "Application Gateway name"
}

output "public_ip_address" {
  value       = azurerm_public_ip.appgw.ip_address
  description = "Application Gateway public IP - API accessible at http://<this-ip>/sum"
}

output "public_ip_id" {
  value       = azurerm_public_ip.appgw.id
  description = "Application Gateway public IP resource ID"
}

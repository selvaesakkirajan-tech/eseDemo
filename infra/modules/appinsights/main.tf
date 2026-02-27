resource "azurerm_application_insights" "main" {
  name                = "${var.environment}-${var.project}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = var.retention_days

  tags = var.tags
}

output "instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.main.app_id
}

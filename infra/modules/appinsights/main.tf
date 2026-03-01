resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.environment}-${var.project}-appinsights-ws"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.environment}-${var.project}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = var.retention_days
  workspace_id        = azurerm_log_analytics_workspace.main.id

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

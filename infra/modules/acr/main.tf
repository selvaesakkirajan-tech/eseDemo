resource "azurerm_container_registry" "main" {
  name                = replace("${var.environment}${var.project}acr", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Enable public access with IP whitelisting for pipelines
resource "azurerm_container_registry_scope_map" "main" {
  name                    = "pull-push"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name
  actions = [
    "repositories/python-api/content/read",
    "repositories/python-api/content/write",
  ]
}

output "id" {
  value       = azurerm_container_registry.main.id
  description = "ACR resource ID"
}

output "login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "ACR login server"
}

output "name" {
  value       = azurerm_container_registry.main.name
  description = "ACR name"
}

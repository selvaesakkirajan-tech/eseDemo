# Public IP for Application Gateway frontend
resource "azurerm_public_ip" "appgw" {
  name                = "${var.environment}-${var.project}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Application Gateway - Standard_v2
resource "azurerm_application_gateway" "main" {
  name                = "${var.environment}-${var.project}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1  # Fixed capacity (no autoscale) - cost-effective for dev
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "http-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "python-api-pool"
  }

  backend_http_settings {
    name                  = "python-api-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 30

    probe_name = "python-api-health-probe"
  }

  http_listener {
    name                           = "python-api-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "python-api-rule"
    rule_type                  = "Basic"
    http_listener_name         = "python-api-listener"
    backend_address_pool_name  = "python-api-pool"
    backend_http_settings_name = "python-api-http-settings"
    priority                   = 100
  }

  probe {
    name                = "python-api-health-probe"
    protocol            = "Http"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "127.0.0.1"
  }

  tags = var.tags

  # AGIC manages backend pool / routing rules after initial creation
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      frontend_port,
      tags,
    ]
  }
}

# Grant AKS identity Contributor on the App Gateway (required by AGIC)
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = var.aks_identity_principal_id
}

# Grant AKS identity Reader on the resource group (required by AGIC)
resource "azurerm_role_assignment" "aks_rg_reader" {
  scope                = var.resource_group_id
  role_definition_name = "Reader"
  principal_id         = var.aks_identity_principal_id
}

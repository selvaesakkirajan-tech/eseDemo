resource "azurerm_public_ip" "appgw" {
  name                = "${var.environment}-${var.project}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_subnet" "appgw" {
  name                 = "${var.environment}-${var.project}-appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.appgw_subnet_cidr]
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.environment}-${var.project}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  sku {
    name     = var.appgw_sku_name
    tier     = var.appgw_sku_tier
    capacity = var.appgw_capacity
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 30
    pick_host_name_from_backend_address = true
  }

  backend_address_pool {
    name = "backend-address-pool"
    // IP addresses will be configured via AGIC
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-address-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 1
  }

  // AGIC managed resource indicator
  tags = merge(
    var.tags,
    {
      "agic.azure.io/enabled" = "true"
    }
  )
}

# User Assigned Identity for AGIC
resource "azurerm_user_assigned_identity" "agic" {
  name                = "${var.environment}-${var.project}-agic-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Grant AGIC identity permissions to manage App Gateway
resource "azurerm_role_assignment" "agic_appgw" {
  scope       = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id = azurerm_user_assigned_identity.agic.principal_id
}

# Grant AGIC identity (Reader) on resource group
resource "azurerm_role_assignment" "agic_rg_reader" {
  scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id = azurerm_user_assigned_identity.agic.principal_id
}

data "azurerm_client_config" "current" {}

output "appgw_public_ip" {
  value       = azurerm_public_ip.appgw.ip_address
  description = "Public IP address of Application Gateway"
}

output "appgw_id" {
  value       = azurerm_application_gateway.main.id
  description = "Application Gateway resource ID"
}

output "appgw_name" {
  value       = azurerm_application_gateway.main.name
  description = "Application Gateway name"
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.appgw.id
  description = "App Gateway subnet ID"
}

output "agic_identity_id" {
  value       = azurerm_user_assigned_identity.agic.id
  description = "AGIC identity resource ID"
}

output "agic_principal_id" {
  value       = azurerm_user_assigned_identity.agic.principal_id
  description = "AGIC principal ID for role assignments"
}

output "agic_client_id" {
  value       = azurerm_user_assigned_identity.agic.client_id
  description = "AGIC client ID"
}

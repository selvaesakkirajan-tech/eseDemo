resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.environment}-${var.project}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope              = var.docker_registry_id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.environment}-${var.project}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.environment}-${var.project}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    vnet_subnet_id  = var.vnet_subnet_id
    os_sku          = "Ubuntu"

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.254.0.0/16"
    dns_service_ip    = "10.254.0.10"
  }

  http_application_routing_enabled = false
  azure_policy_enabled             = true

  tags = var.tags

  depends_on = [azurerm_role_assignment.aks_acr_pull]
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via Azure Pipelines
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-${var.project}-rg"
  location = var.azure_region

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Container Registry
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  project             = var.project
  acr_sku             = var.acr_sku

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )
}

# Virtual Network
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  project             = var.project
  vnet_cidr           = var.vnet_cidr
  subnet_cidr         = var.subnet_cidr

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )
}

# Application Gateway with AGIC
module "appgw_agic" {
  source = "./modules/appgw_agic"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  project             = var.project
  vnet_name           = module.network.vnet_name
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  appgw_sku_name      = var.appgw_sku_name
  appgw_sku_tier      = var.appgw_sku_tier
  appgw_capacity      = var.appgw_capacity

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.network]
}

# AKS Cluster
module "aks" {
  source = "./modules/aks"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  environment               = var.environment
  project                   = var.project
  kubernetes_version        = var.kubernetes_version
  node_count                = var.node_count
  vm_size                   = var.vm_size
  vnet_subnet_id            = module.network.subnet_id
  docker_registry_url       = module.acr.login_server
  docker_registry_id        = module.acr.id

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.network, module.acr]
}

# Application Insights
module "appinsights" {
  source = "./modules/appinsights"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  project             = var.project
  workspace_id        = null # Optional: link to Log Analytics workspace

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )
}

output "aks_cluster_id" {
  value       = module.aks.cluster_id
  description = "AKS cluster ID"
}

output "aks_cluster_name" {
  value       = module.aks.cluster_name
  description = "AKS cluster name"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR login server URL"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name"
}

output "appgw_public_ip" {
  value       = module.appgw_agic.appgw_public_ip
  description = "Application Gateway public IP address"
}

output "appgw_id" {
  value       = module.appgw_agic.appgw_id
  description = "Application Gateway resource ID"
}

output "appgw_name" {
  value       = module.appgw_agic.appgw_name
  description = "Application Gateway name"
}

output "agic_identity_id" {
  value       = module.appgw_agic.agic_identity_id
  description = "AGIC managed identity ID"
}

output "agic_client_id" {
  value       = module.appgw_agic.agic_client_id
  description = "AGIC client ID for use in Helm"
}

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



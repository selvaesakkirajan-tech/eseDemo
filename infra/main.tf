terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
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
  appgw_subnet_cidr   = var.appgw_subnet_cidr

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

# Cosmos DB
module "cosmosdb" {
  source = "./modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  project             = var.project

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )
}

# Application Gateway + AGIC
module "appgw_agic" {
  source = "./modules/appgw_agic"

  resource_group_name       = azurerm_resource_group.main.name
  resource_group_id         = azurerm_resource_group.main.id
  location                  = azurerm_resource_group.main.location
  environment               = var.environment
  project                   = var.project
  appgw_subnet_id           = module.network.appgw_subnet_id
  aks_identity_principal_id = module.aks.identity_principal_id

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.aks, module.network]
}

# Azure Key Vault - stores sensitive secrets (Cosmos keys + ACR/SP secrets added by pipeline)
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  environment              = var.environment
  project                  = var.project
  cosmos_primary_key       = module.cosmosdb.primary_key
  cosmos_connection_string = module.cosmosdb.connection_string
  cosmos_endpoint          = module.cosmosdb.endpoint

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.cosmosdb]
}

# Seed initial users into Cosmos DB
# Re-runs automatically whenever scripts/seed_users.py changes
resource "null_resource" "seed_users" {
  triggers = {
    # Re-run if seed script content changes (catches new/updated users)
    seed_file_hash = filemd5("${path.root}/../scripts/seed_users.py")
    # Re-run if the Cosmos container is recreated
    cosmos_container_id = module.cosmosdb.container_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      pip install --quiet azure-cosmos passlib[bcrypt]
      python "${path.root}/../scripts/seed_users.py"
    EOT

    environment = {
      COSMOS_ENDPOINT  = module.cosmosdb.endpoint
      COSMOS_KEY       = module.cosmosdb.primary_key
      COSMOS_DATABASE  = module.cosmosdb.database_name
      COSMOS_CONTAINER = module.cosmosdb.container_name
    }
  }

  depends_on = [module.cosmosdb]
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

output "cosmos_endpoint" {
  value       = module.cosmosdb.endpoint
  description = "Cosmos DB endpoint URI"
}

output "cosmos_account_name" {
  value       = module.cosmosdb.account_name
  description = "Cosmos DB account name"
}

output "cosmos_primary_key" {
  value       = module.cosmosdb.primary_key
  description = "Cosmos DB primary key"
  sensitive   = true
}

output "key_vault_name" {
  value       = module.keyvault.key_vault_name
  description = "Key Vault name"
}

output "key_vault_uri" {
  value       = module.keyvault.key_vault_uri
  description = "Key Vault URI"
}

output "appgw_public_ip" {
  value       = module.appgw_agic.public_ip_address
  description = "App Gateway public IP - API at http://<this-ip>/sum"
}

output "appgw_id" {
  value       = module.appgw_agic.appgw_id
  description = "App Gateway resource ID (used by AGIC)"
}

output "appgw_name" {
  value       = module.appgw_agic.appgw_name
  description = "App Gateway name"
}



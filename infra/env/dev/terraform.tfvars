environment        = "dev"
project            = "esedemo"
azure_region       = "eastus"
acr_sku            = "Basic"
vnet_cidr          = "10.0.0.0/16"
subnet_cidr        = "10.0.1.0/24"
appgw_subnet_cidr  = "10.0.2.0/24"
kubernetes_version = "1.32"
node_count         = 2
vm_size            = "Standard_B2s"

# Application Gateway configuration (IP-only access, no domain)
appgw_sku_name = "Standard_v2"
appgw_sku_tier = "Standard_v2"
appgw_capacity = 2

common_tags = {
  Project     = "eseDemo"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CreatedDate = "2026-02-27"
}

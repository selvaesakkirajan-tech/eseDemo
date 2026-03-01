environment        = "dev"
project            = "esedemo"
azure_region       = "eastus"
acr_sku            = "Basic"
vnet_cidr          = "10.0.0.0/16"
subnet_cidr        = "10.0.1.0/24"
kubernetes_version = "1.32"
node_count         = 2
vm_size            = "Standard_DC2ads_v5"

common_tags = {
  Project     = "eseDemo"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CreatedDate = "2026-02-27"
}

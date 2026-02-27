variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod"
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "esedemo"
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "acr_sku" {
  description = "Azure Container Registry SKU"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium"
  }
}

variable "vnet_cidr" {
  description = "Virtual Network CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "AKS subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "appgw_subnet_cidr" {
  description = "Application Gateway subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10"
  }
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "appgw_sku_name" {
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "Standard", "WAF_v2", "WAF"], var.appgw_sku_name)
    error_message = "Must be Standard_v2, Standard, WAF_v2, or WAF"
  }
}

variable "appgw_sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "Standard", "WAF_v2", "WAF"], var.appgw_sku_tier)
    error_message = "Must be Standard_v2, Standard, WAF_v2, or WAF"
  }
}

variable "appgw_capacity" {
  description = "Application Gateway capacity (instance count)"
  type        = number
  default     = 2
  validation {
    condition     = var.appgw_capacity >= 1 && var.appgw_capacity <= 125
    error_message = "Capacity must be between 1 and 125"
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "eseDemo"
    ManagedBy   = "Terraform"
    CreatedDate = "2026-02-27"
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, qa, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "vnet_name" {
  type        = string
  description = "Virtual Network name"
}

variable "appgw_subnet_cidr" {
  type        = string
  description = "CIDR block for Application Gateway subnet"
  default     = "10.0.2.0/24"
}

variable "appgw_sku_name" {
  type        = string
  description = "SKU name for Application Gateway"
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "Standard", "WAF_v2", "WAF"], var.appgw_sku_name)
    error_message = "SKU name must be Standard_v2, Standard, WAF_v2, or WAF"
  }
}

variable "appgw_sku_tier" {
  type        = string
  description = "SKU tier for Application Gateway"
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "Standard", "WAF_v2", "WAF"], var.appgw_sku_tier)
    error_message = "SKU tier must be Standard_v2, Standard, WAF_v2, or WAF"
  }
}

variable "appgw_capacity" {
  type        = number
  description = "Number of instances for Application Gateway"
  default     = 2
  validation {
    condition     = var.appgw_capacity >= 1 && var.appgw_capacity <= 125
    error_message = "Capacity must be between 1 and 125"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

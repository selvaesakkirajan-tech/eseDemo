variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID (for Reader role assignment for AGIC)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "appgw_subnet_id" {
  description = "Dedicated App Gateway subnet ID"
  type        = string
}

variable "aks_identity_principal_id" {
  description = "AKS user-assigned identity principal ID - granted Contributor on App Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Resource group name"
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

variable "cosmos_primary_key" {
  description = "Cosmos DB primary key to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "cosmos_connection_string" {
  description = "Cosmos DB primary connection string to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "cosmos_endpoint" {
  description = "Cosmos DB endpoint URI to store in Key Vault"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

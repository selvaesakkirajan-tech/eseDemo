variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.27"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vnet_subnet_id" {
  type = string
}

variable "docker_registry_url" {
  type = string
}

variable "docker_registry_id" {
  type = string
}

variable "appgw_id" {
  type        = string
  description = "Resource ID of the Application Gateway for AGIC add-on"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

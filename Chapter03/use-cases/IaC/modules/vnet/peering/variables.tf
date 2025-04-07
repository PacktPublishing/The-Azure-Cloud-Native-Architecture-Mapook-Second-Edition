variable "hub_vnet_name" {
  type        = string
  description = "Name of the Hub vnet"
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the Hub vnet"
}

variable "hub_resource_group_name" {
  type        = string
  description = "Name of the resource group where the virtual network will be deployed"
}

variable "spoke_vnet_name" {
  type        = string
  description = "Name of the Spoke vnet"
}

variable "spoke_vnet_id" {
  type        = string
  description = "Resource ID of the Spoke vnet"
}

variable "allow_hub_gateway_transit" {
  type        = string
  description = "Boolean to allow gateway transit. Default to false"
  default     = false
}

variable "allow_spoke_gateway_transit" {
  type        = string
  description = "Boolean to allow gateway transit. Default to false"
  default     = false
}

variable "spoke_resource_group_name" {
  type        = string
  description = "Name of the resource group where the virtual network will be deployed"
}
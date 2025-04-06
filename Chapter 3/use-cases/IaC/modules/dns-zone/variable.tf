variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
}

variable "name" {
  type        = string
  description = "The name of the private dns zone."
}

variable "virtual_network_links" {
  description = "The virtual network links of the private DNS Zone"
  type = map(object(
    {
      virtual_network_id   = string
      registration_enabled = optional(bool, false)
    }
  ))
}

variable "tags" {
  description = "Tags to apply to the resource."
  type        = map(string)
  default     = {}
}
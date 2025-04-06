variable "resource_group_name"{
    type = string
    description = "RG name"
}
variable "vnet_name"{
    type = string
    description = "Virtual Network Name"
}
variable "subnet_name"{
    type = string
    description = "Virtual Network Name"
}
variable "subnet_address_prefixes"{
    type = list(any)
    description = "The addres space of the subnet"    
}

variable "private_endpoint_network_policies_enabled" {
    type = bool
    description = "Make private endpoints sensitive to NSGs and UDRs"
    default = true
}
variable "service_delegation"{
    type = string
    description = "The service to which the subnet is delegated"
    default = null
}
variable "delegation_actions" {
  type = list(any)
  description = "Actions performed by the service"
  default = [null]
}
variable "tags"{
    description = "resource tags"
    type = map(string)
    default = {}
}
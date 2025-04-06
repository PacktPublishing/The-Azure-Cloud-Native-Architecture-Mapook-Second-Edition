variable "resource_group_location"{
    type = string
    description = "RG location"
}
variable "resource_group_name"{
    type = string
    description = "RG name"
}
variable "vnet_name"{
    type = string
    description = "Virtual Network Name"
}
variable "vnet_address_space"{
    type = list(any)
    description = "The addres space(s) of the VNET"
    default = [  ]
}
variable "dns_servers"{
    type = list(string)
    description = "DNS servers/endpoints linked to the Virtual Network"
    default = []
}

variable "tags"{
    description = "resource tags"
    type = map(string)
    default = {}
}
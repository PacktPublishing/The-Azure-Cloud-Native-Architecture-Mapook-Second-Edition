variable "route_table_name"{
    type=string
}
variable "resource_group_name"{
    type=string
}
variable "location"{
    type=string
}

variable "bgp_route_propagation_enabled"{
  type=bool
  default=false
}
variable "routes" {
  type=map(object({
    address_prefix = string
    next_hop_type = string
    next_hop_in_ip_address = string
  }))
}
variable "subnet_id" {
  type = string 
}
variable "tags"{
    description = "resource tags"
    type = map(string)
    default = {}
}
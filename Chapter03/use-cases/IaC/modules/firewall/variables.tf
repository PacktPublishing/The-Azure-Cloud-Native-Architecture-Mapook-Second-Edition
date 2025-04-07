variable "name"{
    type=string
}
variable "resource_group_name"{
    type=string
}
variable "location"{
    type=string
}
variable "firewall_policy_id" {
  type = string 
}
variable "ip_configuration_blocks"{  
  type=map(object({    
    pip=string
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
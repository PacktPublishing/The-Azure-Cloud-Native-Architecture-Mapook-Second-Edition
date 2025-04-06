variable "resource_group_location"{
    type = string
    description = "RG location"
}
variable "resource_group_name"{
    type = string
    description = "RG name"
}

variable "tags"{
    description = "resource tags"
    type = map(string)
    default = {}
}
variable "sku_tier" {
    type = string
    default = "Regional" 
}
variable "pip_address_sku" {
  type=string
}
variable "location" {
  type = string 
  
}
variable "resource_group_name" {
  type = string 
}
variable "pip_address_name" {
  type = string 
}
variable "allocation_method" {
  type = string 
}
variable "domain_name_label" {
  type = string 
  default = null
}
variable "zones" {
  type=list(string)
  default = null
}
variable "tags" {
  type=map(string)
  default = {}
}
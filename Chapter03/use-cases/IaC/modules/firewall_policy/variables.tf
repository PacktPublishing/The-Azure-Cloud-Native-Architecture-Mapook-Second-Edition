variable "resource_group_name" {
  type=string
}
variable "firewall_policy_name" {
  type=string
}
variable "location" {
  type=string
}
variable "sku" {
  type=string
}
variable "base_policy_id" {
  type=string
  default = null
}
variable "proxy_enabled"{
  type=bool
  default=false
}
variable "private_ip_ranges" {
  type=list(any)
  default=null
}
variable "dns_servers"{
  type=list(any)
  default=null
}
variable "threat_intelligence_mode" {
  type=string
  default = "Alert"
}
variable "tags" {
  type=map(string)
  default = {}
}




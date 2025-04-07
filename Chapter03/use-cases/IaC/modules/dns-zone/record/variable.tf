variable "private_dns_a_record_name" {
  type        = string
  description = "The name of a record."
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
}

variable "private_dns_a_record_zone_name" {
  type        = string
  description = "The name of the private dns zone in which the record belongs."
}

variable "ttl" {
  type        = string
  description = "The time to live of the a record."
  default     = "300"
}

variable "records" {
  type        = list(string)
  description = "A list of IPv4 records."
}
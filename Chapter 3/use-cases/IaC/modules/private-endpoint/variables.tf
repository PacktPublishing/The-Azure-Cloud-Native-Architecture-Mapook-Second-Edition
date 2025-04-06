variable "resource_group_name" {
  type        = string
  description = "Name of the resource Group"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the Private Endpoints"
}

variable "parent_type" {
  type        = string
  description = "Name of the parent resource type"
}

variable "parent_name" {
  type        = string
  description = "Name of the parent resource"
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the parent resource"
}

variable "subnet_id" {
  type        = string
  description = "id of the subnet where the private endpoint will be created"
}

variable "zone_name"{
  type=string
}
variable "zone_id"{
  type=string
}

variable "tags" {
  description = "Tags to apply to the resource."
  type        = map(string)
  default     = {}
}
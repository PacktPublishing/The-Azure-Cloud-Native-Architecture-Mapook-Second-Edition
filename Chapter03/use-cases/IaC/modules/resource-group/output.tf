output "name" {
  description = "RG name"
  value = azurerm_resource_group.rg.name
  sensitive = false
}
output "location"{
    description = "RG location"
    value = azurerm_resource_group.rg.location
    sensitive = false
}
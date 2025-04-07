output "name" {
  description = "VNET name"
  value = azurerm_virtual_network.vnet.name
  sensitive = false
}
output "location"{
    description = "VNET location"
    value = azurerm_virtual_network.vnet.location
    sensitive = false
}
output "id"{
    description = "VNET identifier"
    value = azurerm_virtual_network.vnet.id
}
resource "azurerm_virtual_network" "vnet" {
  name  =   var.vnet_name  
  location  =   var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers = var.dns_servers

  tags = var.tags
}
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "${var.spoke_vnet_name}to${var.hub_vnet_name}"
  resource_group_name          = var.spoke_resource_group_name
  virtual_network_name         = var.spoke_vnet_name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.allow_spoke_gateway_transit
  use_remote_gateways = var.allow_hub_gateway_transit
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {  
  name                         = "${var.hub_vnet_name}to${var.spoke_vnet_name}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = var.spoke_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.allow_hub_gateway_transit
}
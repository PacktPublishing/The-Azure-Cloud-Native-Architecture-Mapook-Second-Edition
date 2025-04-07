
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_virtual_network_link" {
  for_each              = var.virtual_network_links
  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = each.value["virtual_network_id"]
  registration_enabled  = each.value["registration_enabled"]
}
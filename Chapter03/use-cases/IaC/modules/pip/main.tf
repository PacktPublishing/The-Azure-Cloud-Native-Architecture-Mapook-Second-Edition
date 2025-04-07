resource "azurerm_public_ip" "pip" {   
  name                = var.pip_address_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.pip_address_sku
  sku_tier = var.sku_tier
  domain_name_label = var.domain_name_label
  zones = var.zones

  tags=var.tags
}
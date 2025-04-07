resource "azurerm_firewall" "firewall" {  
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = []
  firewall_policy_id  = var.firewall_policy_id
  dynamic "ip_configuration" {
    for_each = var.ip_configuration_blocks
    content {
      name=ip_configuration.key
      subnet_id = ip_configuration.key == "ip_configuration" ? var.subnet_id : null
      public_ip_address_id = ip_configuration.value.pip
    }
  }
  
  tags = var.tags
}
resource "azurerm_subnet" "subnet" {  
  name                 = var.subnet_name
  resource_group_name =  var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.subnet_address_prefixes
  private_endpoint_network_policies = "Enabled"
  

  dynamic "delegation" {
    for_each = var.service_delegation == null ? [] : [1]
    content {
      name = "${var.subnet_name}-delegation"
      service_delegation {
        name = var.service_delegation
        actions = var.delegation_actions
      }
      
    }
  }
}
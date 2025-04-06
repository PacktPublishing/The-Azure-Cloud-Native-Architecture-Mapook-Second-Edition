terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.66.0"
    }
  }
}

resource "azurerm_private_endpoint" "privateEndpoint" {
  name                = format("pep-%s", var.parent_name)
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = format("pep-%s", var.parent_name)
    private_connection_resource_id = var.parent_id
    is_manual_connection           = false
    subresource_names              = [replace(var.parent_type, "_geo", "")]
  }
  private_dns_zone_group{
    name=var.zone_name
    private_dns_zone_ids = [var.zone_id]
  }
  tags = var.tags
}
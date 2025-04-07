resource "azurerm_private_dns_a_record" "private_dns_a_record" {
  name                = var.private_dns_a_record_name
  zone_name           = var.private_dns_a_record_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = var.ttl
  records             = var.records
}
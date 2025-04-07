output "id" {
  description = "The id of the private dns zone."
  value       = azurerm_private_dns_zone.private_dns_zone.id
}

output "name" {
  description = "the name of the private dns zone"
  value       = azurerm_private_dns_zone.private_dns_zone.name
}
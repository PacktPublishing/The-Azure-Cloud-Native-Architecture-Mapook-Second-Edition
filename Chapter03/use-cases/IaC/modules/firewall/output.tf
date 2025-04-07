output "id"{
    value = azurerm_firewall.firewall.id
}
output "private_ip_address"{
    value = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}
output "name"{
    value = azurerm_firewall.firewall.name
}
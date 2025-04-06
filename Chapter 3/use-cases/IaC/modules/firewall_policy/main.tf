resource "azurerm_firewall_policy" "firewall_policy" {  
  name                = var.firewall_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                      = var.sku
  private_ip_ranges = var.private_ip_ranges
  base_policy_id = var.base_policy_id

  dns {
    servers = var.dns_servers
    proxy_enabled = var.proxy_enabled    
  }
  threat_intelligence_mode = var.threat_intelligence_mode
  tags = var.tags
}
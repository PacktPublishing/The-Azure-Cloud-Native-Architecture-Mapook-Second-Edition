resource "azurerm_firewall_policy_rule_collection_group" "policygroup" {
  name               = var.collection_group_name
  firewall_policy_id = var.firewall_policy_id
  priority           = var.collection_group_priority   

  dynamic "application_rule_collection" {
    for_each = var.application_rule_collections
    content {
      name = application_rule_collection.key
      priority = application_rule_collection.value.priority
      action = application_rule_collection.value.action
      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name=rule.key
          dynamic "protocols"{
            for_each = rule.value.protocol_block
            content {
              type=protocols.value.type
              port=protocols.value.port
            }
          }
          source_addresses = rule.value.source_addresses
          source_ip_groups = rule.value.source_ip_groups
          destination_urls = rule.value.destination_urls
          destination_fqdns = rule.value.destination_fqdns
          destination_fqdn_tags = rule.value.destination_fqdn_tags
          destination_addresses = rule.value.destination_addresses
          terminate_tls = rule.value.terminate_tls
        }        
      }
    }
  }
  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections
    content {
      name = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action = network_rule_collection.value.action

      dynamic "rule"{
        for_each = network_rule_collection.value.rules
        content{
            name=rule.key
            protocols=rule.value.protocols
            destination_ports = rule.value.destination_ports
            source_addresses=rule.value.source_addresses
            source_ip_groups=rule.value.source_ip_groups
            destination_fqdns=rule.value.destination_fqdns
            destination_addresses=rule.value.destination_addresses
            destination_ip_groups=rule.value.destination_ip_groups
        }
      }
   }
  } 
  

  dynamic "nat_rule_collection" {    
    for_each = var.nat_rule_collections
    content {
      name=nat_rule_collection.key
      priority = nat_rule_collection.value.priority
      action=nat_rule_collection.value.action
      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
            content {
              name = rule.key
              protocols=rule.value.protocols
              source_addresses=rule.value.source_addresses
              source_ip_groups=rule.value.source_ip_groups
              destination_ports=rule.value.destination_ports
              destination_address=rule.value.destination_address
              translated_address=rule.value.translated_address
              translated_fqdn=rule.value.translated_fqdn
              translated_port=rule.value.translated_port
            }
        }

      }
    }

  }
  
  

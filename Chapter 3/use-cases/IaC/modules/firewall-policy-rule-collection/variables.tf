variable "collection_group_name" {
  type=string
}
variable "firewall_policy_id" {
  type=string
}
variable "collection_group_priority" {
  type=string
}
variable "application_rule_collections" {
  default = {}
  type=map(object(
    {
      priority=number
      action=string
      rules=map(object(
        {
          protocol_block=list(object({
              type=string
              port=number
          }))
          source_addresses=list(string)
          source_ip_groups=list(string)
          destination_urls=list(string)
          destination_fqdns=list(string)
          destination_addresses=list(string)
          destination_fqdn_tags=list(string)
          terminate_tls=bool
        }
      ))
  }))
  }



variable "network_rule_collections" {
  default = {}
  type=map(object(
    {
      priority=number
      action=string
      rules=map(object(
        {
          protocols=list(string)
          destination_ports=list(string)
          source_addresses=list(string)
          source_ip_groups=list(string) 
          destination_fqdns=list(string)
          destination_addresses=list(string)
          destination_ip_groups=list(string)                  
        }
      ))
    }
  ))
}
variable "nat_rule_collections" {
  default = {}
  type=map(object({
    priority=number
    action=string
    rules=map(object(
      {
        protocols=list(string)
        source_addresses=list(string)
        source_ip_groups=list(string)      
        destination_ports=list(string)
        destination_address=string
        translated_address=string
        translated_fqdn=string
        translated_port=number  
        
      }
    ))
  }))
}
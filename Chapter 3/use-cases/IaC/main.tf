terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.25.0"
    }

  }
   
}
provider "azurerm" {
    features {}
    subscription_id="f63a908a-c054-4d45-a1fd-1eadaee67ffc"
}
module "contoso-rg"{
    source = "./modules/resource-group/"
    resource_group_location = local.config.location
    resource_group_name = local.config.resourceGroup
}

module "vnets"{    
    source = "./modules/vnet/"
    for_each = local.vnets
    vnet_name = each.value.name 
    resource_group_location = module.contoso-rg.location
    resource_group_name = module.contoso-rg.name
    vnet_address_space = [each.value.address_space]
}
module "subnets"{    
  source = "./modules/vnet/subnet/"
  for_each = local.subnets

  subnet_name                 = each.value.subnet_name
  resource_group_name  = module.contoso-rg.name
  vnet_name = each.value.vnet_name
  subnet_address_prefixes     = [each.value.address_prefix]
  depends_on = [module.vnets]
}

module "peering"{
  source = "./modules/vnet/peering/"
  for_each = local.peerings
  hub_vnet_name = each.value.hub_vnet_name
  hub_resource_group_name = module.contoso-rg.name
  hub_vnet_id = module.vnets[each.value.hub_vnet_name].id
  spoke_vnet_name = each.value.spoke_vnet_name
  spoke_resource_group_name = module.contoso-rg.name
  spoke_vnet_id = module.vnets[each.value.spoke_vnet_name].id
  allow_spoke_gateway_transit = false
  allow_hub_gateway_transit = false
}

module "main-hub-fw-pip" {
  source = "./modules/pip/"
  resource_group_name=module.contoso-rg.name  
  location = module.contoso-rg.location  
  pip_address_name = "mainhub-fw-pip"
  pip_address_sku = "Standard"
  allocation_method = "Static"  
}
module "ingress-hub-fw-pip" {
  source = "./modules/pip/"
  resource_group_name=module.contoso-rg.name 
  location = module.contoso-rg.location  
  pip_address_name = "ingresshub-fw-pip"
  pip_address_sku = "Standard"
  allocation_method = "Static"  
}
module "aag-pip" {
  source = "./modules/pip/"
  resource_group_name=module.contoso-rg.name  
  location = module.contoso-rg.location  
  pip_address_name = "aag-fw-pip"
  pip_address_sku = "Standard"
  allocation_method = "Static"
  domain_name_label = "${local.config.backend-prefix}"
}

module "main-hub-firewall" {
  source = "./modules/firewall/"
  name = "mainhub-fw"
  resource_group_name=module.contoso-rg.name  
  location = module.contoso-rg.location
  firewall_policy_id = module.firewall-policies["mainhub-fw-policy"].id
  
  ip_configuration_blocks = {
    ip_configuration = {
      pip = module.main-hub-fw-pip.id
    }
  }
  
  subnet_id = module.subnets["main-hub-AzureFirewallSubnet"].id
  depends_on = [module.subnets]
}

module "ingress-hub-firewall" {
  source = "./modules/firewall/"
  name = "ingress-fw"
  resource_group_name=module.contoso-rg.name  
  location = module.contoso-rg.location
  firewall_policy_id = module.firewall-policies["ingresshub-fw-policy"].id
  ip_configuration_blocks = {
    ip_configuration = {
      pip = module.ingress-hub-fw-pip.id
    }
  }
  subnet_id = module.subnets["ingress-hub-AzureFirewallSubnet"].id
  depends_on = [module.subnets]
}

module "websites_dns_zone" {
  source = "./modules/dns-zone/"

  name                = "privatelink.azurewebsites.net"
  resource_group_name = module.contoso-rg.name  
  virtual_network_links = {
    "ingress-hub" = {
      virtual_network_id = module.vnets["ingress-hub"].id
    }
  }  
}

module "website"{
  source = "./modules/web-app/"
  webappname = local.config.backend-prefix
  resource_group_name = module.contoso-rg.name  
  location = module.contoso-rg.location
  
}
module "webapp_private_endpoint" {
  source = "./modules/private-endpoint/"
  resource_group_name             = module.contoso-rg.name
  resource_group_location         = module.contoso-rg.location
  parent_type = "sites"
  parent_name = module.website.name
  parent_id = module.website.id 
  subnet_id = module.subnets["online-archetype-inbound"].id
  zone_id = module.websites_dns_zone.id
  zone_name="privatelink.azurewebsites.net"
  depends_on = [module.subnets]
}

module "application_gateway" {
  source = "./modules/application-gateway/"

  resource_group_name        = module.contoso-rg.name  
  resource_group_location    = module.contoso-rg.location
  application_gateway_name   = "contoso-app-gateway"
  subnet_id                  = module.subnets["ingress-hub-waf"].id
  depends_on = [module.subnets]

  frontend_ip_configurations = [
    {
      name                          = "publicfrontendip"
      public_ip_address_id          = module.aag-pip.id
      private_ip_address            = null
      private_ip_address_allocation = null
      subnet_id                     = null
    },
    {
      name                          = "privatefrontendip"
      public_ip_address_id          = null
      private_ip_address            = cidrhost("10.0.0.0/26", 5)
      private_ip_address_allocation = "Static"
      subnet_id                     = module.subnets["ingress-hub-waf"].id
    }
  ]

  frontend_ports = [
    {
      name = "onlinespoke1port"
      port = 80
    }
  ]

  backend_addresses = [
    {
      name      = "onlinespoke1pool"
      fqdns = ["${module.website.name}.azurewebsites.net"]
    }
  ]

  backend_settings = [
    {
      name                  = "httpSetting"
      cookie_based_affinity = "Disabled"
      pick_host_name_from_backend_address = false
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
      probe                 = "onlinespoke1probe"
      hostname              = "${module.website.name}.azurewebsites.net"
    }
  ]
  probes = [
    {
        name="onlinespoke1probe"
        path="/"
        protocol="Http"
    }
  ]
  http_listeners = [
    {
      name                      = "listener"
      frontend_ip_configuration = "publicfrontendip"
      frontend_port_name        = "onlinespoke1port"
      protocol                  = "Http"
      
    }
  ]

  routing_rules = [
    {
      name                       = "routingRule"
      rule_type                  = "Basic"
      priority                   = 10
      http_listener_name         = "listener"
      backend_address_pool_name  = "onlinespoke1pool"
      backend_http_settings_name = "httpSetting"
    }
  ] 

  
}
module "route_table" {
  for_each = local.route_tables

  source = "./modules/route-table/"

  route_table_name               = each.key
  resource_group_name            = module.contoso-rg.name
  location                       = module.contoso-rg.location
  bgp_route_propagation_enabled = false
  

  routes     = each.value.routes
  subnet_id  = module.subnets[each.value.subnet].id
  depends_on = [module.subnets]
}
module "firewall-policies" {
  for_each = local.firewall-policies-map
  source = "./modules/firewall_policy/"
  resource_group_name=module.contoso-rg.name  
  location = module.contoso-rg.location
  firewall_policy_name=each.key
  sku = each.value.sku
}
module "firewall_rules" {
  for_each = local.config.firewall_rule_collection_groups

  source = "./modules/firewall-policy-rule-collection/"

  firewall_policy_id          = module.firewall-policies[each.value.target_policy].id
  collection_group_name       = each.key
  collection_group_priority   = each.value.priority
  application_rule_collections = each.value.application_rule_collections
  network_rule_collections     = each.value.network_rule_collections
  nat_rule_collections         = each.value.nat_rule_collections
}

locals {
  config = yamldecode(file("config.yaml"))
   vnets = {
    for vnet in local.config.virtual_networks :
    vnet.name => vnet
  }
  firewall-policies-map = {
    for fw in local.config.firewall-policies : fw.name => fw
  }
  peerings = {
    for peering in local.config.peerings :
    peering.name => peering
  }
  route_tables = {
    for rt in local.config["route-tables"] :
    rt.name => {
      subnet = rt.subnet
      routes = {
        for r in rt.routes :
        r.name => {
          address_prefix         = r.destination
          next_hop_type          = r.next_hop_type
          next_hop_in_ip_address = r.next_hop_in_ip_address
        }
      }
    }
  }
  subnets = merge([
    for vnet in local.config.virtual_networks : {
      for subnet in vnet.subnets :
      "${vnet.name}-${subnet.name}" => {
        vnet_name      = vnet.name
        subnet_name    = subnet.name
        address_prefix = subnet.address_prefix
      }
    }
  ]...)
  
}
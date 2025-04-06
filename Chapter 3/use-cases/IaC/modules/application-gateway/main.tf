#NOTE: in the real-world, you would use TLS, autoscaling, key vault, etc.
resource "azurerm_application_gateway" "app_gw" {
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.value.name
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_addresses
    content {
      name         = backend_address_pool.value.name
      #ip_addresses = backend_address_pool.value.addresses
      fqdns = backend_address_pool.value.fqdns
    }
  }

  #ssl_policy {
  #  policy_name = "AppGwSslPolicy20170401S"
  #  policy_type = "Predefined"
  #}

  dynamic "backend_http_settings" {
    for_each = var.backend_settings
    content {
      name                           = backend_http_settings.value.name
      cookie_based_affinity          = backend_http_settings.value.cookie_based_affinity
      port                           = backend_http_settings.value.port
      protocol                       = backend_http_settings.value.protocol
      request_timeout                = backend_http_settings.value.request_timeout
      probe_name                     = backend_http_settings.value.probe
      host_name                      = backend_http_settings.value.hostname
      trusted_root_certificate_names = backend_http_settings.value.root_certificate_names
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      interval                                  = 30
      name                                      = probe.value.name
      path                                      = probe.value.path
      protocol                                  = probe.value.protocol
      timeout                                   = 30
      unhealthy_threshold                       = 5
      pick_host_name_from_backend_http_settings = true
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.hostname
      firewall_policy_id             = http_listener.value.firewall_policy_id
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.rule_type
      priority                   = request_routing_rule.value.priority
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      url_path_map_name          = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "url_path_map" {
    for_each = var.path_maps
    content {
      name                               = url_path_map.value.name
      default_backend_address_pool_name  = url_path_map.value.backend
      default_backend_http_settings_name = url_path_map.value.backend_set
      dynamic "path_rule" {
        for_each = url_path_map.value["upm"]
        content {
          name                       = path_rule.value.name_rule
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend
          backend_http_settings_name = path_rule.value.backend_set
        }
      }
    }
  } 

  tags = var.tags
}
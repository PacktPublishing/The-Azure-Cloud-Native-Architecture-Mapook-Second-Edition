terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "2.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.7.2"
    }
  }   
}


provider "azapi" {
  # Uses same Azure authentication as azurerm (e.g., via Azure CLI or environment)
}

resource "time_sleep" "rbacpropagation" {
  create_duration = "90s"
  depends_on = [azapi_resource.storage_blob_mi_role]
}
resource "time_sleep" "rbacpropagationadx" {
  create_duration = "90s"
  depends_on = [azapi_resource.adx_database_admin_principal]
  
}
resource "random_string" "eventhub" {
  length  = 13
  upper   = false
  special = false
}
resource "random_uuid" "eventhub-receiver" {}
resource "random_uuid" "fasa-receiver" {}
resource "random_string" "adx" {
  length  = 12
  upper   = false
  special = false
}
resource "random_string" "func" {
  length  = 6
  upper   = false
  special = false
}
resource "random_string" "storage" {
  length  = 6
  upper   = false
  special = false
}

resource "azapi_resource" "rg" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = local.config.resourceGroup
  location  = local.config.location  
}

resource "azapi_resource" "storage" {
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  name      = "${local.prefix}${random_string.storage.result}"
  location  = local.config.location
  parent_id = azapi_resource.rg.id

  body = {
    sku = {
      name = "Standard_LRS"
    }
    kind = "StorageV2"
    properties = {
      accessTier = "Hot"
    }
  }
}
resource "azapi_resource" "storage_blob_mi_role" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("6ba7b812-9dad-11d1-80b4-00c04fd430c8","fasa")	

  parent_id = azapi_resource.storage.id

  body = {
    properties = {     
      roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe" # Storage Blob Data Contributor
      principalId      = azapi_resource.function_app.output.identity.principalId
      principalType    = "ServicePrincipal"
    }
  }

  depends_on = [azapi_resource.function_app]
}

resource "azapi_resource" "app_insights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = "${local.prefix}${random_string.func.result}-ai"
  location  = local.config.location
  parent_id = azapi_resource.rg.id
  response_export_values = ["*"]

  body = {
    kind       = "web"
    properties = {
      Application_Type = "web"
    }
  }
}

resource "azapi_resource" "function_app" {
  type      = "Microsoft.Web/sites@2023-01-01"
  name      = "${local.prefix}${random_string.func.result}"
  location  = local.config.location
  parent_id = azapi_resource.rg.id
  schema_validation_enabled = false
  response_export_values = ["*"]

  body = {
    kind = "functionapp"
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      serverFarmId = null 
      httpsOnly    = true
      siteConfig = {
        appSettings = [
          {
          name  = "AzureWebJobsStorage__accountName"
          value = "${local.prefix}${random_string.storage.result}"
          },
          {
            name  = "AzureWebJobsStorage__credential"
            value = "ManagedIdentity"
          },
          {
            name  = "FUNCTIONS_EXTENSION_VERSION"
            value = "~4"
          },
          {
            name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
            value = azapi_resource.app_insights.output.properties.InstrumentationKey
          },
          {
            name  = "FUNCTIONS_WORKER_RUNTIME"
            value = "dotnet-isolated"
          }
        ]
      }
    }
  }
  
}

resource "null_resource" "zip_deploy" {
  provisioner "local-exec" {
    command = "az functionapp deployment source config-zip --name ${azapi_resource.function_app.name} --resource-group ${azapi_resource.rg.name} --src ./application-code.zip"
  }

  depends_on = [azapi_resource.function_app]
}

data "azapi_resource_action" "function_host_keys" {
  type        = "Microsoft.Web/sites/host@2022-03-01"
  resource_id = "${azapi_resource.function_app.id}/host/default"
  action      = "listkeys"
  method      = "POST"

  response_export_values = ["functionKeys", "systemKeys", "masterKey"]

  depends_on = [time_sleep.rbacpropagation]
}
resource "azapi_resource" "namespace" {
  type      = "Microsoft.EventHub/namespaces@2024-01-01"
  name      = "${local.prefix}${random_string.eventhub.result}"
  location  = local.config.location  
  parent_id = azapi_resource.rg.id
  schema_validation_enabled = false

  body = {    
    properties = {
      
      isAutoInflateEnabled         = false
      maximumThroughputUnits       = 0
      publicNetworkAccess          = "Enabled"
      zoneRedundant                = false
      kafkaEnabled                 = false
    }
  }
}

resource "azapi_resource" "eventhub" {
  type      = "Microsoft.EventHub/namespaces/eventhubs@2024-01-01"
  name      = "temperatures"
  parent_id = azapi_resource.namespace.id

  body = {
    properties = {
      partitionCount           = 2
      messageRetentionInDays  = 1
    }
  }
}

resource "azapi_resource" "stream_analytics_job" {
  type      = "Microsoft.StreamAnalytics/streamingjobs@2020-03-01"
  name      = "temperatureJob"
  location  = local.config.location
  parent_id = azapi_resource.rg.id

  body = {    
     identity = {
      type = "SystemAssigned"
    }
    properties = {      
      sku = {
        name = "Standard"
      }
      eventsOutOfOrderPolicy = "Adjust"
      eventsOutOfOrderMaxDelayInSeconds = 0
      eventsLateArrivalMaxDelayInSeconds = 5
      dataLocale = "en-US"
      compatibilityLevel = "1.2"
    }    
  }
  response_export_values = ["*"]

  
}

resource "azapi_resource" "eventhub_receiver_role" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.eventhub-receiver.result
  parent_id = azapi_resource.eventhub.id
  
  body = {
    properties = {
      roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/a638d3c7-ab3a-418d-83e6-5f17a39d4fde"
      principalId      = azapi_resource.stream_analytics_job.output.identity.principalId
      principalType    = "ServicePrincipal"
    }
  }
}
resource "azapi_resource" "adx_cluster" {
  type      = "Microsoft.Kusto/clusters@2023-08-15"
  name      = "${local.prefix}${random_string.adx.result}"
  location  = local.config.location
  parent_id = azapi_resource.rg.id

  body = {
    sku = {
      name     = "Dev(No SLA)_Standard_D11_v2"
      capacity = 1
      tier     = "Basic"
    }
    properties = {
      enableStreamingIngest = true
    }
  }
}
resource "azapi_resource" "adx_database" {
  type      = "Microsoft.Kusto/clusters/databases@2023-08-15"
  name      = "deviceMetrics"
  location = local.config.location
  parent_id = azapi_resource.adx_cluster.id

  body = {
    kind = "ReadWrite"
    properties = {
      softDeletePeriod = "P30D"
      hotCachePeriod   = "P7D"
    }
  }
}

resource "azapi_resource" "adx_table_script" {
  type      = "Microsoft.Kusto/clusters/databases/scripts@2023-08-15"
  name      = "create-table-sensordata"
  parent_id = azapi_resource.adx_database.id

  body = {
    properties = {
      scriptContent = <<EOT
.create table sensorData (deviceId:string, storeId:string, temperature:double, humidity:int, timestamp:datetime)
EOT
      continueOnErrors = false
      forceUpdateTag   = "v1"
    }
  }

  depends_on = [azapi_resource.adx_database]
}

resource "azapi_resource" "adx_database_admin_principal" {
  type      = "Microsoft.Kusto/clusters/databases/principalAssignments@2024-04-13"
  name      = "sa-job-admin"
  parent_id = azapi_resource.adx_database.id
  schema_validation_enabled = false

  body = {
    properties = {
      principalId   = azapi_resource.stream_analytics_job.output.identity.principalId
      role          = "Admin"
      tenantId      = local.config.tenantId
      principalType = "App"      
    }
  }

  depends_on = [azapi_resource.adx_database]
}


resource "azapi_resource" "stream_analytics_input_eventhub" {
  type      = "Microsoft.StreamAnalytics/streamingjobs/inputs@2020-03-01"
  name      = "temperatures"
  parent_id = azapi_resource.stream_analytics_job.id
  location  = local.config.location
  schema_validation_enabled = false
  body = {
    
    properties = {
      type = "Stream"
      datasource = {
        type = "Microsoft.EventHub/EventHub"
        properties = {
          consumerGroupName = "$Default"
          eventHubName      = "temperatures"
          serviceBusNamespace = azapi_resource.namespace.name
          authenticationMode = "Msi"
          
        }
      }
      serialization = {
        type = "Json"
        properties = {
          encoding = "UTF8"
          format   = "LineSeparated"
        }
      }
    }
  }
}

resource "azapi_resource" "stream_analytics_output_alert" {
  type      = "Microsoft.StreamAnalytics/streamingjobs/outputs@2020-03-01"
  name      = "alert"
  parent_id = azapi_resource.stream_analytics_job.id
  location  = local.config.location
  schema_validation_enabled = false

  depends_on = [data.azapi_resource_action.function_host_keys]
  body = {
    properties = {
      datasource = {
        type = "Microsoft.AzureFunction"
        properties = {
          functionAppName = azapi_resource.function_app.name
          functionName    = "TemperatureFailureAlert"
          apiKey          = data.azapi_resource_action.function_host_keys.output["functionKeys"]["default"]
          maxBatchCount   = 100
          maxBatchSize    = 1000000000
        }
      }
      serialization = {
        type = "Json"
        properties = {
          encoding = "UTF8"
          format   = "LineSeparated"
        }
      }
    }
  }
}


resource "azapi_resource" "stream_analytics_output_adx" {
  type      = "Microsoft.StreamAnalytics/streamingjobs/outputs@2021-10-01-preview"
  name      = "adx"
  parent_id = azapi_resource.stream_analytics_job.id
  location  = local.config.location
  schema_validation_enabled = false
  depends_on = [time_sleep.rbacpropagationadx]
  body = {
    properties = {
      datasource = {
        type = "Microsoft.Kusto/clusters/databases"
        properties = {
          cluster = azapi_resource.adx_cluster.name
          
          database    = "deviceMetrics"
          table      = "sensorData"
          authenticationMode          = "Msi"
          
        }
      }
      serialization = {
        type = "Json"
        properties = {
          encoding = "UTF8"
          format   = "LineSeparated"
        }
      }
    }
  }
}

resource "azapi_resource_action" "patch_stream_analytics_output" {
  type        = "Microsoft.StreamAnalytics/streamingjobs/outputs@2021-10-01-preview"
  resource_id = azapi_resource.stream_analytics_output_adx.id
  method      = "PATCH"
  depends_on = [azapi_resource.stream_analytics_output_adx]

  body = {
    properties = {
      datasource = {
        type = "Microsoft.Kusto/clusters/databases"
        properties = {
          cluster            = "https://${azapi_resource.adx_cluster.name}.${local.config.location}.kusto.windows.net"
          database           = "deviceMetrics"
          table              = "sensorData"
          authenticationMode = "Msi"
        }
      }
    }
  }
}

resource "azapi_resource" "asa_query" {
  type      = "Microsoft.StreamAnalytics/streamingjobs/transformations@2020-03-01"
  name      = "transformation"
  parent_id = azapi_resource.stream_analytics_job.id

  body = {
    properties = {
      streamingUnits      = 1
      query               = "SELECT deviceId, storeId, temperature, humidity, timestamp INTO adx FROM temperatures TIMESTAMP BY timestamp; SELECT deviceId, storeId, System.Timestamp AS alertGeneratedAt, AVG(temperature) AS avgTemp, 'ALERT: Avg temp > 3°C over 1 minutes' AS alertMessage INTO alert FROM temperatures TIMESTAMP BY timestamp GROUP BY deviceId, storeId, TumblingWindow(minute, 5) HAVING AVG(temperature) > 3;"      
    }
  }  
}

locals {
  config         = yamldecode(file("./config.yaml"))  
  prefix        = "mapbook"
}
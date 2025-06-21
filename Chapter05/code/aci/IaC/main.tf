terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "2.3.0"
    }
  }   
}

# using azapi because azurerm falls short with logic apps and connections
provider "azapi" {
  # Uses same Azure authentication as azurerm (e.g., via Azure CLI or environment)
}


resource "azapi_resource" "mapbook-aci" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = local.config.resourceGroup
  location  = local.config.location
}
#storage account to which you can upload files to be processed by the Logic App, which will create one ACI per blob
resource "azapi_resource" "storage_account" {
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  name      = local.config.storageAccountName
  location  = local.config.location
  parent_id = azapi_resource.mapbook-aci.id

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      minimumTlsVersion = "TLS1_2"
      allowBlobPublicAccess = true
      accessTier = "Hot"
    }
  }
}
# default blob container
resource "azapi_resource" "blob_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01"
  name      = "blobs"
  parent_id = "${azapi_resource.storage_account.id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"  # No anonymous access
    }
  }
}
# used by the logic app to iterate over the blobs in the container
resource "azapi_resource" "storage_connection" {
    type      = "Microsoft.Web/connections@2016-06-01"
    name      = "azureblob-connection"
    location  = local.config.location
    parent_id = azapi_resource.mapbook-aci.id
    schema_validation_enabled = false

    body = {
    properties = {
      displayName = "Azure Blob Storage Connection"
      api = {
        id = "/subscriptions/${local.config.subscriptionId}/providers/Microsoft.Web/locations/${local.config.location}/managedApis/azureblob"
      }
      parameterValueSet = {
        #authentication = jsonencode({
        #  type = "ManagedServiceIdentity"
        #})
        name="managedIdentityAuth"
        values="token"
      }
    }
  }
}
# used by the logic app to create the ACI
resource "azapi_resource" "aci_connection" {
    type      = "Microsoft.Web/connections@2016-06-01"
    name      = "aci-connection"
    location  = local.config.location
    parent_id = azapi_resource.mapbook-aci.id
    schema_validation_enabled = false

    body = {
    properties = {
      displayName = "ACI Connection"
      alternativeParameterValues = {
        
      }
      parameterValueType ="Alternative"
      api = {
        id = "/subscriptions/${local.config.subscriptionId}/providers/Microsoft.Web/locations/${local.config.location}/managedApis/aci"
      }      
    }
  }
}

resource "azapi_resource" "logic_app" {
  type      = "Microsoft.Logic/workflows@2019-05-01"
  name      = "aci-orchestration"
  location  = local.config.location
  parent_id = azapi_resource.mapbook-aci.id
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      state = "Enabled"
      definition = {
        "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowDefinition.json#"
        contentVersion = "1.0.0.0"
        parameters = {
            "$connections" = {
                type = "Object"
            }
        }

        triggers = {
          manual = {
            type = "Request"
            kind = "Http"
            inputs = {
              schema = {}
            }
          }
        }
        actions = {
          Lists_blobs_V2 = {
            runAfter = {}
            type = "ApiConnection"
            metadata = {
              "JTJmYmxvYnM=": "/blobs"
            }
            inputs = {
              host = {
                connection = {
                  name = "@parameters('$connections')['azureblob-connection']['connectionId']"
                }
              }
              method = "get"
              path = "/v2/datasets/@{encodeURIComponent(encodeURIComponent('${local.config.storageAccountName}'))}/foldersV2/@{encodeURIComponent(encodeURIComponent('JTJmYmxvYnM='))}",
              
            }
          },
          For_Each  = {
            runAfter = {
              Lists_blobs_V2 = ["Succeeded"]
            }
            type = "Foreach"
            
              foreach = "@outputs('Lists_blobs_V2')['body']['value']"
              actions = {
                Create_or_update_a_container_group = {
                  type = "ApiConnection"
                  inputs = {
                    host = {
                      connection = {
                        name = "@parameters('$connections')['aci-connection']['connectionId']"
                      }
                    }
                    method = "put"
                    path = "/subscriptions/@{encodeURIComponent('${local.config.subscriptionId}')}/resourceGroups/@{encodeURIComponent('${local.config.resourceGroup}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent(guid())}"
                    queries = {
                      "x-ms-api-version" = "2023-05-01"
                    }
                    body = {
                      location = "${local.config.location}"
                      properties = {
                        containers = [
                          {
                            name = "blob-container-instance"
                            properties = {
                              image = "${local.config.containerImage}"
                              resources = {
                                requests = {
                                  cpu = "1"
                                  memoryInGB = "1"
                                }
                              }
                              environmentVariables = [
                                {
                                  name  = "BlobName"
                                  value = "@items('For_each')['Name']"
                                }
                              ]
                            }
                          }
                        ]
                        osType = "Linux"
                        sku = "Standard"                          
                        restartPolicy = "Never"
                      }
                    }
                  }
                }
              }
            
          }
        }
        outputs = {}
      }
    parameters = {
      "$connections" = {
        type = "Object"
          value = {
            "azureblob-connection" = {
              "id": "/subscriptions/${local.config.subscriptionId}/providers/Microsoft.Web/locations/${local.config.location}/managedApis/azureblob",
              connectionId=azapi_resource.storage_connection.id
              connectionName="azureblob-connection"
              connectionProperties = {
                authentication = {
                  type = "ManagedServiceIdentity"
                }
              }
            },
            "aci-connection" = {
            "id": "/subscriptions/${local.config.subscriptionId}/providers/Microsoft.Web/locations/${local.config.location}/managedApis/aci",
            connectionId=azapi_resource.aci_connection.id
            connectionName="aci-connection"
            connectionProperties = {
              authentication = {
                type = "ManagedServiceIdentity"
              }
            }
          }
          }
          
        }
      }
    }
  }
  response_export_values = ["*"]
}


resource "azapi_resource" "aci-cleanup" {
  type      = "Microsoft.Logic/workflows@2019-05-01"
  name      = "aci-cleanup"
  location  = local.config.location
  parent_id = azapi_resource.mapbook-aci.id
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      state = "Enabled"
      definition = {
        "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowDefinition.json#"
        contentVersion = "1.0.0.0"
        parameters = {
            "$connections" = {
                type = "Object"
            }
        }

        triggers = {
          manual = {
            type = "Request"
            kind = "Http"
            inputs = {
              schema = {}
            }
          }
        }
        actions = {
          Get_a_list_of_container_groups_in_a_resource_group = {
            runAfter = {}
            type = "ApiConnection"
            
            inputs = {
              host = {
                connection = {
                  name = "@parameters('$connections')['aci-connection']['connectionId']"
                }
              }
              method = "get"              
              path = "/subscriptions/@{encodeURIComponent('${local.config.subscriptionId}')}/resourceGroups/@{encodeURIComponent('${local.config.resourceGroup}')}/providers/Microsoft.ContainerInstance/containerGroups"
              queries = {
                      "x-ms-api-version" = "2023-05-01"
                    }
              
            }
          },
          For_Each  = {
            runAfter = {
              Get_a_list_of_container_groups_in_a_resource_group = ["Succeeded"]
            }
            type = "Foreach"            
              foreach = "@body('Get_a_list_of_container_groups_in_a_resource_group')?['value']"
              actions = {
                "Condition": {
                        "actions": {
                            "Get_properties_of_a_container_group": {
                                "type": "ApiConnection",
                                "inputs": {
                                    "host": {
                                        "connection": {
                                            "name": "@parameters('$connections')['aci-connection']['connectionId']"
                                        }
                                    },
                                    "method": "get",
                                    "path": "/subscriptions/@{encodeURIComponent('${local.config.subscriptionId}')}/resourceGroups/@{encodeURIComponent('${local.config.resourceGroup}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent(item()?['name'])}",
                                    "queries": {
                                        "x-ms-api-version": "2023-05-01"
                                    }
                                }
                            },
                            "Condition_1": {
                                "actions": {
                                    "Delete_a_container_group": {
                                        "type": "ApiConnection",
                                        "inputs": {
                                            "host": {
                                                "connection": {
                                                    "name": "@parameters('$connections')['aci-connection']['connectionId']"
                                                }
                                            },
                                            "method": "delete",
                                            "path": "/subscriptions/@{encodeURIComponent('${local.config.subscriptionId}')}/resourceGroups/@{encodeURIComponent('${local.config.resourceGroup}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent(item()?['name'])}",
                                            "queries": {
                                                "x-ms-api-version": "2023-05-01"
                                            }
                                        }
                                    }
                                },
                                "runAfter": {
                                    "Get_properties_of_a_container_group": [
                                        "Succeeded"
                                    ]
                                },
                                "else": {
                                    "actions": {}
                                },
                                "expression": {
                                    "and": [
                                        {
                                            "equals": [
                                                "@body('Get_properties_of_a_container_group')?['properties']?['containers'][0]?['properties']?['instanceView']?['currentState']?['state']",
                                                "Terminated"
                                            ]
                                        }
                                    ]
                                },
                                "type": "If"
                            }
                        },
                        "else": {
                            "actions": {}
                        },
                        "expression": {
                            "and": [
                                {
                                    "equals": [
                                        "@item()?['properties']?['provisioningState']",
                                        "Succeeded"
                                    ]
                                }
                            ]
                        },
                        "type": "If"
                    }
              }
            
          }
        }
        outputs = {}
      }
    parameters = {
      "$connections" = {
        type = "Object"
          value = {            
            "aci-connection" = {
            "id": "/subscriptions/${local.config.subscriptionId}/providers/Microsoft.Web/locations/${local.config.location}/managedApis/aci",
            connectionId=azapi_resource.aci_connection.id
            connectionName="aci-connection"
            connectionProperties = {
              authentication = {
                type = "ManagedServiceIdentity"
              }
            }
          }
          }
          
        }
      }
    }
  }
  response_export_values = ["*"]
}
resource "random_uuid" "blob_contributor" {}
resource "random_uuid" "aci_manager" {}
resource "random_uuid" "aci_manager_cleanup" {}
resource "azapi_resource" "logic_app_storage_role_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.blob_contributor.result
  parent_id = azapi_resource.storage_account.id

  body = {
    properties = {
      roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
      principalId      = azapi_resource.logic_app.output.identity.principalId


      principalType    = "ServicePrincipal"
    }
  }
}

resource "azapi_resource" "logic_app_aci_role_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.aci_manager.result
  parent_id = azapi_resource.mapbook-aci.id

  body = {
    properties = {
      roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/6a453b05-0be6-4b91-95c6-83c209136b3c"
      principalId      = azapi_resource.logic_app.output.identity.principalId


      principalType    = "ServicePrincipal"
    }
  }
}

resource "azapi_resource" "cleanup_logic_app_aci_role_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.aci_manager_cleanup.result
  parent_id = azapi_resource.mapbook-aci.id

  body = {
    properties = {
      roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/5d977122-f97e-4b4d-a52f-6b43003ddb4d"
      principalId      = azapi_resource.aci-cleanup.output.identity.principalId


      principalType    = "ServicePrincipal"
    }
  }
}


locals {
  config = yamldecode(file("config.yaml"))
}
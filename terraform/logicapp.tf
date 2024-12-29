# resource "azurerm_storage_account" "logicsa" {
#   name                     = "logicsaforjoyce"
#   resource_group_name      = azurerm_resource_group.logicrg.name
#   location                 = azurerm_resource_group.logicrg.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

# resource "azurerm_service_plan" "AppServicePlan" {
#   name                = "resumeserviceplan"
#   location            = azurerm_resource_group.logicrg.location
#   resource_group_name = azurerm_resource_group.logicrg.name
#   os_type             = "Linux"
#   sku_name            = "Y1"
# }

# resource "azurerm_logic_app_standard" "notifyteams" {
#   name                       = "notifyteams"
#   location                   = azurerm_resource_group.logicrg.location
#   resource_group_name        = azurerm_resource_group.logicrg.name
#   app_service_plan_id        = azurerm_service_plan.AppServicePlan.id
#   storage_account_name       = azurerm_storage_account.logicsa.name
#   storage_account_access_key = azurerm_storage_account.logicsa.primary_access_key

#   app_settings = {
#     "FUNCTIONS_WORKER_RUNTIME"     = "node"
#     "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
#   }
# }

resource "azurerm_logic_app_workflow" "alertworkflow" {
  name                = "alertworkflow"
  location            = azurerm_resource_group.backend.location
  resource_group_name = azurerm_resource_group.backend.name
}

resource "azurerm_logic_app_trigger_http_request" "httptrigger" {
  name         = "httptrigger"
  # a workflow is an 'app' with consumption, an integration account is the logic app linked to it?
  logic_app_id = azurerm_logic_app_workflow.alertworkflow.id
  method = "POST"
  schema = <<SCHEMA
{
    "type": "object",
    "properties": {
        "schemaId": {
            "type": "string"
        },
        "data": {
            "type": "object",
            "properties": {
                "essentials": {
                    "type": "object",
                    "properties": {
                        "alertId": {
                            "type": "string"
                        },
                        "alertRule": {
                            "type": "string"
                        },
                        "severity": {
                            "type": "string"
                        },
                        "signalType": {
                            "type": "string"
                        },
                        "monitorCondition": {
                            "type": "string"
                        },
                        "monitoringService": {
                            "type": "string"
                        },
                        "alertTargetIDs": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            }
                        },
                        "configurationItems": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            }
                        },
                        "originAlertId": {
                            "type": "string"
                        },
                        "firedDateTime": {
                            "type": "string"
                        },
                        "resolvedDateTime": {
                            "type": "string"
                        },
                        "description": {
                            "type": "string"
                        },
                        "essentialsVersion": {
                            "type": "string"
                        },
                        "alertContextVersion": {
                            "type": "string"
                        }
                    }
                },
                "alertContext": {
                    "type": "object",
                    "properties": {
                        "properties": {},
                        "conditionType": {
                            "type": "string"
                        },
                        "condition": {
                            "type": "object",
                            "properties": {
                                "windowSize": {
                                    "type": "string"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
SCHEMA
}

resource "azurerm_logic_app_action_custom" "calloutlook" {
  name         = "calloutlook"
  logic_app_id = azurerm_logic_app_workflow.alertworkflow.id

  body = <<BODY
{
  "type": "ApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "referenceName": "outlook"
      }
    },
    "method": "post",
    "body": {
      "To": "joyceheyue@live.com",
      "Subject": "Alert/Terraform",
      "Body": "<p class=\"editor-paragraph\">@{triggerBody()?['data']?['essentials']?['severity']}</p><p class=\"editor-paragraph\">@{triggerBody()?['data']?['essentials']?['alertId']}<br>Successful Alerts.</p><p class=\"editor-paragraph\">Please check the Portal.</p>",
      "Importance": "Normal"
    },
    "path": "/v2/Mail"
  },
  "runAfter": {}
}
BODY
}
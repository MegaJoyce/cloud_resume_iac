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

# TODO: below resource failed. 
resource "azurerm_logic_app_action_custom" "calloutlook" {
  name         = "calloutlook"
  logic_app_id = azurerm_logic_app_workflow.alertworkflow.id

  body = <<BODY
{
  "type": "ApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "name": "outlook"
        "connectionId": ""
        "id": ""
      }
    },
    "method": "post",
    "body": {
      "To": "joyceheyue@live.com",
      "Subject": "alert",
      "Body": "<p class=\"editor-paragraph\">@{triggerBody()?['data']?['essentials']?['severity']}</p><p class=\"editor-paragraph\">@{triggerBody()?['data']?['essentials']?['alertId']}<br>Successful Alerts.</p><p class=\"editor-paragraph\">Please check the Portal.</p>",
      "Importance": "High"
    },
    "path": "/v2/Mail"
  },
  "runAfter": {},
}
BODY
}
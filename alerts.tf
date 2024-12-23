resource "azurerm_resource_group" "monitorrg" {
  name     = var.backend_rg
  location = var.location
}

resource "azurerm_storage_account" "matrixmonitor" {
  name                     = "matrixmonitor"
  resource_group_name      = azurerm_resource_group.monitorrg.name
  location                 = azurerm_resource_group.monitorrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# when dry run/terraform plan, data will still connect to the subscription and fetch the resource information, 
# therefore, if this resource does not exist, terraform will report error. 
# data "azurerm_logic_app_standard" "notifyteams" {
#   name                = "notifyteams"
#   resource_group_name = var.backend_rg
# }

resource "azurerm_monitor_action_group" "action_grp" {
  name                = "monitor_action_group"
  resource_group_name = azurerm_resource_group.monitorrg.name
  short_name          = "monactgrp"

  logic_app_receiver {
    name                    = "logicappaction"
    resource_id             = azurerm_logic_app_workflow.workflow1.id
    # two ways to resolve the issue: one is below; another way is to fetch the url in pipeline workflow and pass it to terraform.
    callback_url            = azurerm_logic_app_trigger_http_request.trigger.callback_url
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "apiaccesscount" {
  name                = "apiaccesscount"
  resource_group_name = azurerm_resource_group.monitorrg.name
  scopes              = [azurerm_storage_account.matrixmonitor.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
      threshold = 20
      metric_namespace = "Microsoft.Web/sites"
      metric_name = "FunctionExecutionCount"
      operator = "GreaterThan"
      aggregation = "Total"
      skip_metric_validation = false
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_grp.id
  }
}
resource "azurerm_monitor_action_group" "action_grp" {
  name                = "monitor_action_group"
  resource_group_name = azurerm_resource_group.backend.name
  short_name          = "monactgrp"

  email_receiver {
    name = "Yue He"
    email_address = "joyceheyue@live.com"
    use_common_alert_schema = true
  }
  logic_app_receiver {
    name                    = "logicappaction"
    resource_id             = azurerm_logic_app_workflow.alertworkflow.id
    # two ways to resolve the issue: one is below; another way is to fetch the url in pipeline workflow and pass it to terraform.
    callback_url            = azurerm_logic_app_trigger_http_request.httptrigger.callback_url
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "apiaccesscount" {
  name                = "apiaccesscount"
  resource_group_name = azurerm_resource_group.backend.name
  scopes              = [azurerm_linux_function_app.FunctionApp.id]
  description         = "Action will be triggered when FunctionExecutionCount is greater than 20 every minute."

  # these criteria are from the JSON view of the alert rule.
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
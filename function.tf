resource "azurerm_resource_group" "functionrg" {
  name     = var.backend_rg
  location = var.location
}

resource "azurerm_storage_account" "functionsa" {
  name                     = "functionsajoyceheyue"
  resource_group_name      = azurerm_resource_group.functionrg.name
  location                 = azurerm_resource_group.functionrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "AppServicePlan" {
  name                = "resumeserviceplan"
  location            = azurerm_resource_group.functionrg.location
  resource_group_name = azurerm_resource_group.functionrg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

data "azurerm_cosmosdb_account" "cosmosdb" {
  name                = var.cosmodb
  resource_group_name = var.cosmodb_rg
}


resource "azurerm_linux_function_app" "FunctionApp" {
  name                = "resumeapi4joyce"
  location            = azurerm_resource_group.functionrg.location
  resource_group_name = azurerm_resource_group.functionrg.name
  service_plan_id     = azurerm_service_plan.AppServicePlan.id

  storage_account_name       = azurerm_storage_account.functionsa.name
  storage_account_access_key = azurerm_storage_account.functionsa.primary_access_key

  site_config {
    application_stack {
      python_version = "3.10"
    }
    cors {
      allowed_origins = ["https://www.joyceheyue.fun", "https://portal.azure.com"]
    }
  }

  app_settings = {
    "ConsmoDbConnectionString" : data.azurerm_cosmosdb_account.cosmosdb.primary_sql_connection_string
  }
}

resource "azurerm_function_app_function" "httptrigger" {
  name            = "resume_httptrigger"
  function_app_id = azurerm_linux_function_app.FunctionApp.id
  language        = "Python"
  test_data = jsonencode({
    "name" = "Azure"
  })
  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "anonymous"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
    ]
  })
}
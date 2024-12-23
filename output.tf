output "cosmodb_connection_string" {
  value     = data.azurerm_cosmosdb_account.cosmosdb.primary_sql_connection_string
  sensitive = true
}

output "function_app_id" {
  value = azurerm_linux_function_app.FunctionApp.id
}

output "website_storage_account" {
  value = azurerm_storage_account.joycesaforweb.name
}
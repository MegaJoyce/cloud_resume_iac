resource "azurerm_storage_account" "joycesaforweb" {
  name                     = "joycesaforweb"
  resource_group_name      = azurerm_resource_group.frontend.name
  location                 = azurerm_resource_group.frontend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "resume" {
  storage_account_id = azurerm_storage_account.joycesaforweb.id
  index_document     = "index.html"
}
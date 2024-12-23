resource "azurerm_resource_group" "frontendrg" {
  name     = var.frontend_rg
  location = var.location
}

resource "azurerm_storage_account" "joycesaforweb" {
  name                     = "joycesaforweb"
  resource_group_name      = azurerm_resource_group.frontendrg.name
  location                 = azurerm_resource_group.frontendrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "resume_web"
  }
}

resource "azurerm_storage_account_static_website" "resume" {
  storage_account_id = azurerm_storage_account.joycesaforweb.id
  index_document     = "index.html"
}
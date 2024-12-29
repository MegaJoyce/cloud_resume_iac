# backend: alerts + funtion + logicapp
resource "azurerm_resource_group" "backend" {
  name = var.backend_rg
  location = var.location
}

# storage account with static website enabled
resource "azurerm_resource_group" "frontend" {
  name = var.frontend_rg
  location = var.location
}
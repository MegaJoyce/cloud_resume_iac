terraform {
  required_version = "1.9.5"
  required_providers {
    azurerm = {
      version = "~> 4.14.0"
      source  = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfbackendstatesajoyce"
    container_name = "terraformstate"
    key = joyceresume.tfstate
  }
}
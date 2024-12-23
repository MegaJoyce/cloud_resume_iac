terraform {
  required_version = "1.9.5"
  required_providers {
    azurerm = {
      version = "~> 4.14.0"
      source  = "hashicorp/azurerm"
    }
    random = {
      version = "3.6.3"
      source  = "hashicorp/random"
    }
  }
}
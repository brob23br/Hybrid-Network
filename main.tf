terraform {
  required_version = "~> 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

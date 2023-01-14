terraform {
  required_version = ">= 1.1.7"

  backend "azurerm" {
    container_name       = "terraformstate"
    key                  = "terraform-1.tfstate"
    storage_account_name = "stterrasesadvstatedev"
    resource_group_name  = "rg-terrasesadv-state-dev"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.27.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}

// create resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform"
  location = "westeurope"
}

// create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
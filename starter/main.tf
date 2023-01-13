# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.27.0"
    }
  }

  required_version = ">= 1.1.7"
}

locals {
  location = "westeurope"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-myFirstTFGroup-we-001"
  location = local.location
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/24"]
  location            = local.location
  name                = "vnet-myfirstvnet-we-001"
  resource_group_name = azurerm_resource_group.rg.name
}

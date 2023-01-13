terraform {
  required_version = ">= 1.1.7"

  backend "azurerm" {
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
    storage_account_name = "stterrasesadvstatedev"
    resource_group_name  = "rg-terrasesadv-state-dev"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.31.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "cloudflare" {
}

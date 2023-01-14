locals {
  project_name = "tfsessionadvanced5"
  location     = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}-${var.environment}"
  location = local.location
}

module "vnet" {
  source              = "./modules/vnet"
  environment         = var.environment
  project_name        = local.project_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "website" {
  source               = "./modules/website"
  environment          = var.environment
  project_name         = local.project_name
  location             = local.location
  resource_group_name  = azurerm_resource_group.rg.name
  integrationsubnet_id = module.vnet.integration_subnet_id
}

module "keyvault" {
  source                     = "./modules/keyvault"
  environment                = var.environment
  project_name               = local.project_name
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  key_vault_role_assignments = var.key_vault_role_assignments
}

module "sql" {
  source              = "./modules/sql"
  environment         = var.environment
  project_name        = local.project_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  key_vault_id        = module.keyvault.key_vault_id
}

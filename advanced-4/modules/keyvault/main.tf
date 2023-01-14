// Data source to get the current tenant id
data "azurerm_client_config" "current" {}

#tfsec:ignore:azure-keyvault-specify-network-acl
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.project_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
}

// Using for_each to create multiple role assignments
resource "azurerm_role_assignment" "kv_role_assignment" {
  for_each = var.key_vault_role_assignments

  scope                = azurerm_key_vault.kv.id
  role_definition_name = each.value
  principal_id         = each.key
}

// Using the time_offset resource to a date that is 2 months from now
resource "time_offset" "two_months" {
  offset_months = 2
}

// Using the random_password resource to create a random password that will expire in 2 months
resource "random_password" "sql_server_admin_password" {
  length  = 32
  special = false
  keepers = {
    last_changed_date = time_offset.two_months.rfc3339
  }
}

// Using the azurerm_key_vault_secret resource to store the password in the key vault
resource "azurerm_key_vault_secret" "sql_server_admin_password" {
  key_vault_id    = var.key_vault_id
  name            = "sql-admin-password"
  value           = random_password.sql_server_admin_password.result
  content_type    = "Managed by Terraform"
  expiration_date = time_offset.two_months.rfc3339
}

resource "azurerm_mssql_server" "sql_server" {
  name                = "sql-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  version             = "12.0"

  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  administrator_login          = "username"
  administrator_login_password = azurerm_key_vault_secret.sql_server_admin_password.value
}

resource "azurerm_mssql_server_extended_auditing_policy" "audit" {
  server_id              = azurerm_mssql_server.sql_server.id
  log_monitoring_enabled = true
}

resource "azurerm_mssql_database" "sql_database" {
  name                 = "sqldb-${var.project_name}-${var.environment}"
  server_id            = azurerm_mssql_server.sql_server.id
  sku_name             = "Basic"
  storage_account_type = "Local"
}

// Using the azurerm_key_vault_secret resource to store the connection string in the key vault
resource "azurerm_key_vault_secret" "sql_server_connection_string" {
  key_vault_id    = var.key_vault_id
  name            = "sql-${azurerm_mssql_database.sql_database.name}-connection-string"
  value           = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_database.name};Persist Security Info=False;User ID=${azurerm_mssql_server.sql_server.administrator_login};Password=${azurerm_key_vault_secret.sql_server_admin_password.value};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  content_type    = "Managed by Terraform"
  expiration_date = time_offset.two_months.rfc3339
}

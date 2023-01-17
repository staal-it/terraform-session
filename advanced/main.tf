locals {
  project_name = "tfsessionadvanced"
  location     = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}-${var.environment}"
  location = local.location
}

data "azurerm_client_config" "current" {}

#tfsec:ignore:azure-keyvault-specify-network-acl
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.project_name}-${var.environment}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
}

resource "azurerm_role_assignment" "kv_role_assignment" {
  for_each = var.key_vault_role_assignments

  scope                = azurerm_key_vault.kv.id
  role_definition_name = each.value
  principal_id         = each.key
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "integrationsubnet" {
  name                 = "snet-integration-${local.project_name}-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "privendpointsubnet" {
  name                                      = "snet-privendpoint-${local.project_name}-${var.environment}"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.2.0/24"]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-${local.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app_service" {
  name                      = "app-${local.project_name}-${var.environment}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_service_plan.id
  virtual_network_subnet_id = azurerm_subnet.integrationsubnet.id

  site_config {}
}

resource "cloudflare_record" "domain-verification" {
  zone_id = "72e0e6d795ec809b9158033c4a4c73d3"
  name    = "asuid.tf-demo.staal-it.nl"
  value   = azurerm_linux_web_app.app_service.custom_domain_verification_id
  type    = "TXT"
  ttl     = 3600
}

resource "cloudflare_record" "cname-record" {
  zone_id = "72e0e6d795ec809b9158033c4a4c73d3"
  name    = "tf-demo"
  value   = azurerm_linux_web_app.app_service.default_hostname
  type    = "CNAME"
  ttl     = 3600
}

resource "azurerm_app_service_custom_hostname_binding" "hostname-binding" {
  hostname            = "tf-demo.staal-it.nl"
  app_service_name    = azurerm_linux_web_app.app_service.name
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [
    cloudflare_record.domain-verification,
    cloudflare_record.cname-record
  ]
}

resource "time_offset" "one_month" {
  offset_months = 1
}

resource "time_offset" "two_months" {
  offset_months = 2
}

resource "random_password" "sql_server_admin_password" {
  length  = 32
  special = false
  keepers = {
    last_changed_date = time_offset.one_month.rfc3339
  }
}

resource "azurerm_key_vault_secret" "sql_server_admin_password" {
  key_vault_id    = azurerm_key_vault.kv.id
  name            = "sql-admin-password"
  value           = random_password.sql_server_admin_password.result
  content_type    = "Managed by Terraform"
  expiration_date = time_offset.two_months.rfc3339
}

resource "azurerm_mssql_server" "sql_server" {
  name                = "sql-${local.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  name                 = "sqldb-${local.project_name}-${var.environment}"
  server_id            = azurerm_mssql_server.sql_server.id
  sku_name             = "Basic"
  storage_account_type = "Local"
}

resource "azurerm_key_vault_secret" "sql_server_connection_string" {
  key_vault_id    = azurerm_key_vault.kv.id
  name            = "sql-${azurerm_mssql_database.sql_database.name}-connection-string"
  value           = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_database.name};Persist Security Info=False;User ID=${azurerm_mssql_server.sql_server.administrator_login};Password=${azurerm_key_vault_secret.sql_server_admin_password.value};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  content_type    = "Managed by Terraform"
  expiration_date = time_offset.two_months.rfc3339
}

resource "azurerm_private_dns_zone" "dns_privatezone_sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name                  = "dnszl-sql-${local.project_name}-${var.environment}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_privatezone_sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "sql_privateendpoint" {
  name                = "pep-sql-${local.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privendpointsubnet.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_privatezone_sql.id]
  }

  private_service_connection {
    name                           = "privateendpointconnection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

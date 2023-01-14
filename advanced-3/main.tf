locals {
  project_name = "tfsessionadvanced3"
  location     = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}-${var.environment}"
  location = local.location
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
  name                = "app-${local.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  // Added network integration
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

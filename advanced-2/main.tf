locals {
  project_name = "tfsessionadvanced2"
  location     = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}-${var.environment}"
  location = local.location
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

// Add custom hostname binding

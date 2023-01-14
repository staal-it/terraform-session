resource "azurerm_resource_group" "rg" {
  name     = "rg-tfsessionadvanced-dev"
  location = "westeurope"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-tfsessionadvanced-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app_service" {
  name                = "app-tfsessionadvanced-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {}
}

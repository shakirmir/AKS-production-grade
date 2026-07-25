resource "azurerm_container_registry" "acr" {
  name                = "${var.name_prefix}acr${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

output "registry_id" {
  value = azurerm_container_registry.acr.id
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

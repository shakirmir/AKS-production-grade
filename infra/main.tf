data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

module "acr" {
  source              = "./modules/acr"
  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

module "keyvault" {
  source              = "./modules/keyvault"
  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tenant_id           = var.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

module "aks" {
  source              = "./modules/aks"
  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tenant_id           = var.tenant_id
  subscription_id     = var.subscription_id
}

resource "azurerm_role_assignment" "acr_pull" {
  count = var.create_rbac_role_assignments ? 1 : 0

  scope                = module.acr.registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}


resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = "Standard"
  resource_type = "Containers"
}

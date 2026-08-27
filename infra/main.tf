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
  source                       = "./modules/aks"
  name_prefix                  = var.name_prefix
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  tenant_id                    = var.tenant_id
  subscription_id              = var.subscription_id
  key_vault_id                 = module.keyvault.vault_id
  create_rbac_role_assignments = var.create_rbac_role_assignments
}

resource "azurerm_role_assignment" "key_vault_operator" {
  count                = var.create_rbac_role_assignments ? 1 : 0
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
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

resource "azurerm_monitor_action_group" "aks" {
  count               = var.alert_email == null ? 0 : 1
  name                = "${var.name_prefix}-aks-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "aksalerts"

  email_receiver {
    name          = "platform-owner"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "aks_node_cpu" {
  count               = var.alert_email == null ? 0 : 1
  name                = "${var.name_prefix}-aks-node-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  description         = "Alert when average AKS node CPU is above 80 percent."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.name_prefix}kv${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  rbac_authorization_enabled  = true
  purge_protection_enabled    = false
  soft_delete_retention_days = 7
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

output "vault_id" {
  value = azurerm_key_vault.kv.id
}

output "vault_name" {
  value = azurerm_key_vault.kv.name
}

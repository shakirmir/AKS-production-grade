resource "azurerm_key_vault" "kv" {
  name                        = "${var.name_prefix}kv${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days = 7
}

resource "azurerm_key_vault_access_policy" "owner" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions = ["Get", "List", "Create", "Delete", "Update", "Import", "Recover", "Backup", "Restore"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

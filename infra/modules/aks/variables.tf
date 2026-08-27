variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "create_rbac_role_assignments" {
  type = bool
}

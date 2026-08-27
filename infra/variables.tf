variable "subscription_id" {
  description = "Azure subscription ID that owns the practice environment."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID for Entra ID / Azure AD integration."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Short prefix for all resources to keep names unique."
  type        = string
  default     = "aksprac"
}

variable "create_rbac_role_assignments" {
  description = "Create the ACR pull and Key Vault workload identity role assignments. Set to true only when the deploying principal has User Access Administrator or Owner permissions."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Optional email address for AKS monitoring alerts. Leave null to provision monitoring without notifications."
  type        = string
  default     = null
}

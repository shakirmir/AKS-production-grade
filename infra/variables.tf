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
  description = "Create RBAC role assignments for the AKS kubelet identity and Application Gateway identity. Set to true only when the deploying principal has User Access Administrator or Owner permissions."
  type        = bool
  default     = false
}

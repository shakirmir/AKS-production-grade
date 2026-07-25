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

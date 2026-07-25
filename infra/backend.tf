terraform {
  backend "azurerm" {
    resource_group_name  = "aks-practice-backend-rg"
    storage_account_name = "akspr9512"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${1:-aks-practice-backend-rg}"
LOCATION="${2:-eastus}"
STORAGE_ACCOUNT="${3:-akspractice$(date +%s)}"
CONTAINER="${4:-tfstate}"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
az storage account create --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --sku Standard_LRS --allow-blob-public-access false
az storage container create --name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" --auth-mode login

echo "Backend configured."
echo "Use these values in your Azure DevOps variable group:"
echo "backendResourceGroup=$RESOURCE_GROUP"
echo "backendStorageAccount=$STORAGE_ACCOUNT"
echo "backendContainer=$CONTAINER"

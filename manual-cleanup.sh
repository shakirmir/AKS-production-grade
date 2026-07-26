#!/bin/bash

# Manual cleanup using Azure CLI
# Usage: ./manual-cleanup.sh

set -euo pipefail

echo "=== Starting manual cleanup of all resources ==="

# Delete AKS cluster
echo "Deleting AKS cluster..."
az aks delete --resource-group aksprac-rg --name aksprac-aks --yes --no-wait || echo "AKS cluster deletion failed or already deleted"

# Delete ACR
echo "Deleting ACR..."
az acr delete --resource-group aksprac-rg --name akspracacru3zgda --yes --no-wait || echo "ACR deletion failed or already deleted"

# Delete Key Vault
echo "Deleting Key Vault..."
az keyvault delete --resource-group aksprac-rg --name aksprackvsuc3yj --no-wait || echo "Key Vault deletion failed or already deleted"

# Delete Log Analytics Workspace
echo "Deleting Log Analytics Workspace..."
az monitor log-analytics workspace delete --resource-group aksprac-rg --name aksprac-law --yes --no-wait || echo "Log Analytics deletion failed or already deleted"

# Delete resource group
echo "Deleting resource group..."
az group delete --name aksprac-rg --yes --no-wait || echo "Resource group deletion failed or already deleted"

echo "=== Cleanup initiated. Resources will be deleted in the background ==="
echo "You can check status with: az group show --name aksprac-rg"

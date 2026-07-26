 # Cleanup script to destroy all resources
# Usage: .\cleanup.ps1

Write-Host "=== Starting cleanup of all resources ==="

# Get AKS credentials
Write-Host "Getting AKS credentials..."
az aks get-credentials --resource-group aksprac-rg --name aksprac-aks --overwrite-existing

# Delete Kubernetes resources
Write-Host "Deleting Kubernetes resources..."
kubectl delete namespace production --ignore-not-found=true
kubectl delete namespace uat --ignore-not-found=true
kubectl delete namespace ingress-nginx --ignore-not-found=true

# Delete remaining resources
Write-Host "Deleting remaining Kubernetes resources..."
kubectl delete all --all --all-namespaces --ignore-not-found=true

Write-Host "=== Kubernetes resources deleted ==="

# Destroy Terraform resources
Write-Host "=== Destroying Terraform resources ==="
cd infra
terraform init -backend-config="resource_group_name=aksprac-tfstate-rg" -backend-config="storage_account_name=akspractfstatesa" -backend-config="container_name=tfstate" -backend-config="key=AKS-production-grade.tfstate"
terraform destroy -auto-approve -var="subscription_id=b2f1e96a-2500-4557-9658-7dea028c06a4" -var="tenant_id=c7d7fabe-6c6d-4fe6-85dc-141d6a150cec" -var="create_rbac_role_assignments=false"

Write-Host "=== All resources destroyed ==="

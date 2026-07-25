#!/usr/bin/env bash
set -euo pipefail

cd infra
terraform init -backend-config="resource_group_name=${BACKEND_RESOURCE_GROUP:-aks-practice-backend-rg}" -backend-config="storage_account_name=${BACKEND_STORAGE_ACCOUNT:-}" -backend-config="container_name=${BACKEND_CONTAINER:-tfstate}" -backend-config="key=terraform.tfstate"
terraform plan -var="subscription_id=${SUBSCRIPTION_ID:-}" -var="tenant_id=${TENANT_ID:-}" -out=tfplan
terraform apply tfplan

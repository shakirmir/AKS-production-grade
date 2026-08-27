#!/usr/bin/env bash
set -euo pipefail

cd infra

BACKEND_RESOURCE_GROUP="${BACKEND_RESOURCE_GROUP:-aks-practice-backend-rg}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-tfstate}"

if [[ -z "${SUBSCRIPTION_ID:-}" || -z "${TENANT_ID:-}" ]]; then
	echo "ERROR: SUBSCRIPTION_ID and TENANT_ID must be set."
	echo "Example: export SUBSCRIPTION_ID=<subscription-id> TENANT_ID=<tenant-id>"
	exit 1
fi

if [[ -z "${BACKEND_STORAGE_ACCOUNT:-}" ]]; then
	echo "ERROR: BACKEND_STORAGE_ACCOUNT is not set."
	echo "Run ./bootstrap-backend.sh, then export the printed backendStorageAccount value."
	echo "Example: export BACKEND_STORAGE_ACCOUNT=akspractice123456"
	exit 1
fi

terraform init -backend-config="resource_group_name=$BACKEND_RESOURCE_GROUP" -backend-config="storage_account_name=$BACKEND_STORAGE_ACCOUNT" -backend-config="container_name=$BACKEND_CONTAINER" -backend-config="key=terraform.tfstate"
terraform plan -var="subscription_id=${SUBSCRIPTION_ID:-}" -var="tenant_id=${TENANT_ID:-}" -out=tfplan
terraform apply tfplan

#!/usr/bin/env bash
set -euo pipefail

cd infra

if [[ -z "${SUBSCRIPTION_ID:-}" || -z "${TENANT_ID:-}" ]]; then
	echo "ERROR: SUBSCRIPTION_ID and TENANT_ID must be set."
	exit 1
fi

if [[ -z "${BACKEND_STORAGE_ACCOUNT:-}" ]]; then
	echo "ERROR: BACKEND_STORAGE_ACCOUNT must be set."
	echo "The backend storage account is not destroyed by this script."
	exit 1
fi

BACKEND_RESOURCE_GROUP="${BACKEND_RESOURCE_GROUP:-aks-practice-backend-rg}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-tfstate}"

terraform init -reconfigure \
	-backend-config="resource_group_name=$BACKEND_RESOURCE_GROUP" \
	-backend-config="storage_account_name=$BACKEND_STORAGE_ACCOUNT" \
	-backend-config="container_name=$BACKEND_CONTAINER" \
	-backend-config="key=terraform.tfstate"
terraform destroy -var="subscription_id=$SUBSCRIPTION_ID" -var="tenant_id=$TENANT_ID" -auto-approve

#!/usr/bin/env bash
set -euo pipefail

cd infra
terraform destroy -var="subscription_id=${SUBSCRIPTION_ID:-}" -var="tenant_id=${TENANT_ID:-}" -auto-approve

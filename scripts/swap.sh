#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-production}"
TARGET_VERSION="${2:-green}"

kubectl -n "$NAMESPACE" patch service aks-practice-app --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/selector/version\", \"value\": \"$TARGET_VERSION\"}]"

#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-production}"

kubectl -n "$NAMESPACE" patch service aks-practice-app --type='json' -p='[{"op": "replace", "path": "/spec/selector/version", "value": "blue"}]'

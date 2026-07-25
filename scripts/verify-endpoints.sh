#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-production}"
SERVICE="${2:-aks-practice-app}"

kubectl -n "$NAMESPACE" get svc "$SERVICE"
kubectl -n "$NAMESPACE" get endpoints "$SERVICE"

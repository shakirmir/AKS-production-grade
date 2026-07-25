#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-uat}"
HOST="${2:-localhost}"

kubectl get pods -n "$NAMESPACE" -l app=aks-practice-app >/dev/null
curl -fsS "http://$HOST/healthz"

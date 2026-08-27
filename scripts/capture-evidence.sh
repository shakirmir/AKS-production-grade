#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-production}"
OUTPUT_DIR="${2:-evidence/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTPUT_DIR"

capture() {
  local name="$1"
  shift
  "$@" >"$OUTPUT_DIR/$name.txt" 2>&1 || true
}

capture cluster kubectl get nodes -o wide
capture namespaces kubectl get namespaces
capture pods kubectl get pods -n "$NAMESPACE" -o wide
capture deployments kubectl get deployments -n "$NAMESPACE" -o wide
capture services kubectl get services -n "$NAMESPACE" -o wide
capture ingress kubectl get ingress -n "$NAMESPACE" -o yaml
capture endpoints kubectl get endpoints -n "$NAMESPACE"
capture network-policies kubectl get networkpolicy -n "$NAMESPACE" -o yaml
capture events kubectl get events -n "$NAMESPACE" --sort-by=.lastTimestamp
capture hpa kubectl get hpa -n "$NAMESPACE"
capture pdb kubectl get pdb -n "$NAMESPACE"
capture workload-identity kubectl get serviceaccount aks-practice-app-sa -n "$NAMESPACE" -o yaml
capture secret-mount kubectl exec -n "$NAMESPACE" deploy/aks-practice-app -- ls -la /mnt/secrets-store

cat <<EOF
Evidence captured in $OUTPUT_DIR
Review and sanitize output before committing it. Do not commit tokens, certificates, or other secrets.
EOF

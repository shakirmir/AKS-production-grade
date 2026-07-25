#!/usr/bin/env bash
set -euo pipefail

kubectl -n production scale deployment aks-practice-app --replicas=12

echo "Trigger an autoscaler scale-up event by increasing demand and watching the node pool." 

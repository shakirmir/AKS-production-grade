#!/usr/bin/env bash
set -euo pipefail

kubectl -n production patch secret tls-secret --type='json' -p='[{"op":"replace","path":"/data/tls.crt","value":""}]'

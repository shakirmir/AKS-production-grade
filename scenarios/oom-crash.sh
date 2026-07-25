#!/usr/bin/env bash
set -euo pipefail

kubectl -n production delete deployment aks-practice-app --ignore-not-found=true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-practice-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-practice-app
      version: green
  template:
    metadata:
      labels:
        app: aks-practice-app
        version: green
    spec:
      containers:
        - name: app
          image: REPLACE_ME_IMAGE
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 250m
              memory: 64Mi
          ports:
            - containerPort: 8080
EOF

#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lockout-role
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: lockout-rolebinding
  namespace: production
subjects:
  - kind: Group
    name: REPLACE_ME_GROUP_OBJECT_ID
roleRef:
  kind: Role
  name: lockout-role
  apiGroup: rbac.authorization.k8s.io
EOF

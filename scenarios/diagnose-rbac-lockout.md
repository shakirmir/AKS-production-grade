# Diagnose RBAC lockout

- Verify the current identity and role bindings:
  - kubectl auth can-i get pods -n production --as <user>
  - kubectl auth can-i get pods -n production
  - kubectl -n production get rolebindings
- Check Azure AD group membership and the cluster authorization config:
  - az ad group show --group <group-object-id> --query displayName
  - az aks show --resource-group <rg> --name <cluster> --query aadProfile

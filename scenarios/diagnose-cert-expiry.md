# Diagnose certificate expiry

- Inspect ingress and secret status:
  - kubectl -n production get ingress
  - kubectl -n production describe ingress aks-practice-app
  - kubectl -n production get secret tls-secret -o yaml
- Inspect the Application Gateway and AGIC logs:
  - az network application-gateway show --resource-group <rg> --name <agw>
  - kubectl -n kube-system logs deploy/agic --tail=100

# Diagnose certificate expiry

- Inspect ingress and secret status:
  - kubectl -n production get ingress
  - kubectl -n production describe ingress aks-practice-app
  - kubectl -n production get secret tls-secret -o yaml
- Inspect the NGINX ingress controller and Azure LoadBalancer service:
  - kubectl -n ingress-nginx get svc ingress-nginx-controller
  - kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=100

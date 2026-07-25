# Diagnose broken green health check

- Inspect pod readiness and events:
  - kubectl -n production get pods
  - kubectl -n production describe pod <pod-name>
  - kubectl -n production logs <pod-name>
- Check the service and endpoints:
  - kubectl -n production get svc aks-practice-app
  - kubectl -n production get endpoints aks-practice-app

# Diagnose OOM crash

- Check pod restarts and events:
  - kubectl -n production get pods
  - kubectl -n production describe pod <pod-name>
  - kubectl -n production logs <pod-name>
- Inspect resource usage and limits:
  - kubectl -n production top pod <pod-name>
  - kubectl -n production get deploy aks-practice-app -o yaml

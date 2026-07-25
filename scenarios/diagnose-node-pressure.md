# Diagnose node pressure

- Inspect pending pods and scheduler events:
  - kubectl -n production get pods
  - kubectl -n production describe pod <pod-name>
  - kubectl -n production get events --sort-by=.metadata.creationTimestamp
- Inspect the cluster node pool and autoscaler:
  - az aks nodepool show --resource-group <rg> --cluster-name <cluster> --name system
  - az aks nodepool show --resource-group <rg> --cluster-name <cluster> --name user

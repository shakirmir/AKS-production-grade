# Daily AKS practice runbook

> Reminder: run ./destroy-infra.sh at the end of any session where you do not need the cluster running overnight.

1. Provision or reuse the infra:
   - Copy infra/terraform.tfvars.example to infra/terraform.tfvars and fill in your Azure subscription and tenant IDs.
   - Run ./bootstrap-backend.sh once to create the Azure Storage Account backend.
   - Export `SUBSCRIPTION_ID` and `TENANT_ID` from your Azure account.
   - Export the backend values printed by the bootstrap script, especially `BACKEND_STORAGE_ACCOUNT`.
   - Example: `export BACKEND_STORAGE_ACCOUNT=<storage-account-name>`
   - Run ./deploy-infra.sh.
2. Build and push the app:
   - az acr login --name <acr-name>
   - docker build -t <acr-login-server>/aks-practice-app:1 app
   - docker push <acr-login-server>/aks-practice-app:1
3. Deploy blue:
   - helm upgrade --install aks-practice-app ./charts/aks-practice-app -n uat --create-namespace -f charts/aks-practice-app/values-uat.yaml --set image.tag=1
   - helm upgrade --install aks-practice-app ./charts/aks-practice-app -n production --create-namespace -f charts/aks-practice-app/values-production.yaml --set version=blue --set service.selectorVersion=blue --set image.tag=1
4. Deploy green and practice a swap:
   - helm upgrade --install aks-practice-app ./charts/aks-practice-app -n production --create-namespace -f charts/aks-practice-app/values-production.yaml --set version=green --set service.selectorVersion=green --set image.tag=1
   - ./scripts/swap.sh production green
   - ./scripts/rollback.sh production
5. Run one scenario script, diagnose it, then fix it.
6. Capture evidence after each deployment or release exercise:
   - `./scripts/capture-evidence.sh production`
   - Review generated files and remove secrets before committing evidence.
7. Review monitoring in Azure Monitor and Log Analytics using the queries in `README.md`.
8. Tear down at the end of the session if needed: `./destroy-infra.sh`.

## Ingress deployment and recovery

The application uses the NGINX Ingress Controller and its Azure LoadBalancer
service. UAT and production share the LoadBalancer IP; the request `Host`
header selects the appropriate Ingress route.

### Required configuration

- The application NetworkPolicy must allow TCP 8080 from the `ingress-nginx`
  namespace. The chart template contains this rule.
- The NGINX service uses `externalTrafficPolicy: Local`. This lets Azure health
  check the Kubernetes node health endpoint, rather than NGINX's
  host-dependent default route.
- `uat.example.internal` and `prod.example.internal` are sample hostnames.
  Create DNS records for your real names, or add temporary Windows hosts-file
  mappings to the LoadBalancer external IP.

### Validate a deployment

```powershell
kubectl get pods -n uat
kubectl get pods -n production
kubectl get svc ingress-nginx-controller -n ingress-nginx
kubectl get ingress -n uat
kubectl get ingress -n production

$ingressPod = kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n ingress-nginx $ingressPod -- curl -i -H "Host: prod.example.internal" http://127.0.0.1/healthz
```

To test an external route before DNS is configured:

```powershell
curl.exe -i http://<load-balancer-ip>/healthz -H "Host: prod.example.internal"
```

The expected response is `HTTP/1.1 200 OK` with `{"status":"ok"}`.

### Diagnose an unreachable external IP

1. Confirm the application pods, service endpoints, Ingress address, and NGINX
   controller are ready.
2. Test the ingress from inside the controller using the command above. A 200
   response proves NGINX can route to the app.
3. Inspect the Azure LoadBalancer service and controller events:

```powershell
kubectl describe svc ingress-nginx-controller -n ingress-nginx
kubectl get endpoints ingress-nginx-controller -n ingress-nginx
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=100
```

4. If DNS fails, point the hostname at the current service external IP. After
   recreating a LoadBalancer service, always recheck the IP because it can
   change.

# Daily AKS practice runbook

> Reminder: run ./destroy-infra.sh at the end of any session where you do not need the cluster running overnight.

1. Provision or reuse the infra:
   - Copy infra/terraform.tfvars.example to infra/terraform.tfvars and fill in your Azure subscription and tenant IDs.
   - Run ./bootstrap-backend.sh once to create the Azure Storage Account backend.
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
6. Tear down at the end of the session if needed: ./destroy-infra.sh.

# End-to-End Implementation Plan

This document outlines the full setup path for the AKS practice environment so it can be implemented step by step against real Azure services.

## 1. Prerequisites

Before starting, confirm the following:
- An active Azure subscription is available.
- Azure CLI is installed and authenticated with `az login`.
- An Azure DevOps organization and project already exist.
- You have permission to create resource groups, AKS, ACR, Key Vault, Application Gateway, Policy assignments, and Defender for Cloud settings.
- You have a tenant ID and subscription ID available.

## 2. Azure Bootstrap

1. Create the Terraform backend storage account:
   - Run `./bootstrap-backend.sh`.
   - Capture the storage account name, resource group, and container name.
2. Create a variable group in Azure DevOps named `aks-practice-vars` with these values:
   - `azureServiceConnection`
   - `subscriptionId`
   - `tenantId`
   - `acrName`
   - `acrLoginServer`
   - `resourceGroupName`
   - `aksClusterName`
   - `backendResourceGroup`
   - `backendStorageAccount`
   - `backendContainer`
3. Create Azure DevOps environments:
   - `infra-approval`
   - `uat-approval`
   - `prod-approval`
   - `prod-swap-approval`
   - `prod-rollback`
4. Configure approval checks in each environment via the Azure DevOps UI.

## 3. Terraform Infrastructure

1. Copy the example file:
   - `cp infra/terraform.tfvars.example infra/terraform.tfvars`
2. Fill in values for:
   - `subscription_id`
   - `tenant_id`
   - `location`
   - `name_prefix`
3. Review the Terraform modules in `infra/`:
   - `modules/aks` for AKS, monitoring, Azure CNI, and AGIC integration
   - `modules/acr` for the registry
   - `modules/keyvault` for the vault and access policy
   - `modules/appgateway` for the gateway and public IP
4. Initialize and plan:
   - `cd infra`
   - `terraform init -backend-config=...`
   - `terraform plan -out=tfplan`
5. Apply:
   - `terraform apply tfplan`
6. Capture outputs:
   - AKS cluster name
   - ACR login server
   - resource group name

## 4. Container Image Build and Push

1. Log in to ACR:
   - `az acr login --name <acr-name>`
2. Build the app image:
   - `docker build -t <acr-login-server>/aks-practice-app:<tag> app`
3. Push the image:
   - `docker push <acr-login-server>/aks-practice-app:<tag>`
4. Make sure the image tag matches the tag used in the pipeline and Helm values.

## 5. Kubernetes Preparation

1. Get cluster credentials:
   - `az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing`
2. Create required namespaces:
   - `kubectl create namespace uat`
   - `kubectl create namespace production`
3. Ensure the cluster has the necessary RBAC and identity prerequisites for workload identity and Key Vault CSI access.
4. Confirm the Application Gateway Ingress Controller is healthy in the cluster.

## 6. Helm Deployment

1. Update the Helm values files:
   - `charts/aks-practice-app/values-uat.yaml`
   - `charts/aks-practice-app/values-production.yaml`
2. Replace placeholders for:
   - ACR login server
   - tenant ID
   - Key Vault name
   - Entra ID group object ID
3. Deploy to UAT:
   - `helm upgrade --install aks-practice-app ./charts/aks-practice-app -n uat --create-namespace -f charts/aks-practice-app/values-uat.yaml`
4. Deploy blue to production:
   - `helm upgrade --install aks-practice-app ./charts/aks-practice-app -n production --create-namespace -f charts/aks-practice-app/values-production.yaml --set version=blue --set service.selectorVersion=blue`
5. Validate pods, service, ingress, and endpoints.

## 7. Azure DevOps Pipeline Flow

The pipeline in `azure-pipelines.yml` is structured to run:
1. Terraform plan on every push.
2. Terraform apply after approval in the `infra-approval` environment.
3. Build and push the container image.
4. Deploy to UAT after approval.
5. Deploy green to production after approval.
6. Swap traffic to green after approval in `prod-swap-approval`.
7. Roll back to blue manually through the `prod-rollback` environment.

## 8. Practice Scenarios

Use the scripts in `scenarios/` to exercise troubleshooting:
- `oom-crash.sh`
- `node-pressure.sh`
- `broken-green-healthcheck.sh`
- `cert-expiry.sh`
- `rbac-lockout.sh`

For each scenario, use the matching diagnosis markdown file in the same folder to guide your investigation.

## 9. Verification Checklist

Confirm each of the following:
- Terraform state is stored in the remote backend.
- AKS cluster is healthy and shows nodes.
- ACR contains the pushed image.
- Pods are running in both namespaces.
- Ingress is creating routing entries through Application Gateway.
- Health checks and service endpoints behave as expected.
- Azure Policy and Defender for Cloud findings can be reviewed.

## 10. Teardown

When the practice session is complete and the environment is no longer needed:
- Run `./destroy-infra.sh`
- Confirm the AKS cluster, Application Gateway, and related resources are removed.

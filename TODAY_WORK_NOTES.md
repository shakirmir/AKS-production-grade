# Today’s Work Summary

## What was created
- Azure DevOps service connection using the existing service principal
- `aks-practice-vars` variable group in Azure DevOps
- Terraform backend storage account configuration values in Azure DevOps
- Manual rollback stage `RollbackToBlue` in `azure-pipelines.yml`

## What was fixed
- Added Terraform install logic into AzureCLI pipeline steps
- Standardized pipeline agent image to `ubuntu-22.04`
- Published `tfplan` artifact in `TerraformPlan` and downloaded it in `TerraformApply`
- Added `terraform init` before `terraform apply tfplan`
- Fixed App Gateway `request_routing_rule` priority in `infra/modules/appgateway/main.tf`
- Confirmed the active ingress architecture is NGINX plus an Azure LoadBalancer Service.
 - Made RBAC role assignments optional via `create_rbac_role_assignments` (default `false`) to avoid pipeline SP needing role-assignment permissions
 - Split Azure DevOps pipelines into `infra-deploy.yml` (manual infra) and `app-deploy.yml` (app CI/CD)
 - Fixed Helm chart issues preventing installs:
    - Guarded `SecretProviderClass` with `secretProvider.enabled` to avoid CRD dependency when CSI is absent
    - Added `autoscaling.enabled: false` to UAT values to prevent HPA nil-pointer template errors
    - Removed the conflicting Application Gateway Ingress annotation and retained the NGINX `spec.ingressClassName`.
 - Optionalized creation of `azurerm_role_assignment` resources in Terraform modules (`count = var.create_rbac_role_assignments ? 1 : 0`)
 - Added/updated Terraform outputs used by pipelines (ACR login server, AKS identities)
 - Verified Helm chart deploys to AKS after the above fixes (Ingress resource created but AG backend not yet populated)
 - Confirmed AGIC is not part of this deployment; Application Gateway remains a documented alternative only.
 - Fixed NGINX ingress reachability:
    - Allowed app traffic from the `ingress-nginx` namespace in the chart NetworkPolicy; the previous policy allowed only `kube-system`, preventing NGINX from reaching the app.
    - Configured the NGINX Helm release with `controller.service.externalTrafficPolicy=Local` in both UAT and production pipeline stages. This prevents Azure from depending on NGINX's host-dependent default route for health checks.
    - Recreated the NGINX LoadBalancer service after an unhealthy external route. Azure assigned a new external IP (`20.253.96.109`) and the production health endpoint returned HTTP 200.
    - Documented DNS, in-cluster ingress, and public LoadBalancer validation steps in `RUNBOOK.md`.

## Key observations
- The pipeline now successfully installs Terraform and initializes all provider plugins
- `RollbackToBlue` is intentionally manual and uses the `prod-rollback` environment
- The service principal must have sufficient Azure permissions to create role assignments
- RBAC role assignments are now opt-in via `create_rbac_role_assignments`, so the initial Terraform apply can proceed without elevated `User Access Administrator` or `Owner` permissions

## Next steps
1. Re-run the Azure DevOps pipeline
2. Approve the `infra-approval` environment when `TerraformPlan` completes
3. Confirm the `TerraformApply` stage can successfully apply the plan
4. If needed, verify the service principal has `Contributor` or stronger access
5. After successful apply, capture outputs for:
   - `acr_login_server`
   - `resource_group_name`
   - `aks_cluster_name`
6. Update the `aks-practice-vars` variable group with the captured outputs

## Useful commands
```bash
# Check SP details
az ad sp show --id <appId>

# List role assignments for the SP
az role assignment list --assignee <appId> --all --query "[].{scope:scope,role:roleDefinitionName}" -o table

# Grant Contributor permission to the SP
az role assignment create --assignee <appId> --role "Contributor" --scope /subscriptions/b2f1e96a-2500-4557-9658-7dea028c06a4
```

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
- Replaced unsupported AGIC extension with the AKS Application Gateway addon in `infra/modules/aks/main.tf`

## Key observations
- The pipeline now successfully installs Terraform and initializes all provider plugins
- `RollbackToBlue` is intentionally manual and uses the `prod-rollback` environment
- The service principal must have sufficient Azure permissions to create role assignments

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

# Runtime Evidence

Run `../scripts/capture-evidence.sh production` after a deployment, traffic swap, rollback, or incident exercise. The script writes sanitized Kubernetes command output into a timestamped directory.

Capture these additional screenshots during the exercise:

- Azure DevOps: Build, DeployUAT, DeployProdGreen, SwapToGreen, and RollbackToBlue stages
- Azure Monitor: AKS node CPU/memory charts and alert history
- Log Analytics: pod logs and restart query results
- Azure portal dashboard: pinned AKS monitoring charts

Never commit kubeconfig files, tokens, certificates, secret values, or unredacted pipeline variables.

# AKS DevOps Interview Preparation

## Project Summary

This project is an end-to-end, production-style AKS practice platform. Terraform provisions Azure infrastructure, Azure DevOps runs separate infrastructure and application pipelines, Docker builds the application image, ACR stores it, and Helm deploys it to AKS. NGINX Ingress is exposed through an Azure Standard Load Balancer. Production releases use blue-green deployment, with manual approval, rollback, health checks, monitoring, and incident exercises.

Use the answers below as talking points. Replace generic wording with what you personally executed, observed, and measured.

## Your 60-Second Introduction

“I built an automated CI/CD workflow for a containerized application running on Azure Kubernetes Service. I used Terraform to provision AKS, ACR, Key Vault, monitoring, and supporting identities. Azure DevOps used one pipeline for reviewed Terraform plan and apply, and another for building and pushing a Docker image, deploying to UAT, deploying a green production version, and switching traffic after approval. Helm packaged the Kubernetes resources. I used AKS workload identity and the Key Vault CSI driver instead of storing cloud credentials in the repository. I also implemented readiness and liveness probes, HPA, PDB, NetworkPolicy, RBAC, ResourceQuota, monitoring, and a manual blue-to-green rollback path. During validation, I diagnosed issues involving Terraform installation, Helm chart dependencies, NetworkPolicy traffic, and the NGINX Load Balancer health check.”

## End-to-End Implementation Explanation

1. **Provision the platform:** Terraform creates the Resource Group, AKS, ACR, Key Vault, Azure CNI networking, workload identity, Log Analytics, Azure Monitor integration, and optional alerts. State is stored remotely in Azure Storage. The infrastructure pipeline runs `terraform plan`, publishes the plan artifact, waits for approval, and applies that same plan.
2. **Build the artifact:** Azure DevOps builds the Python application into a Docker image, tags it with `Build.BuildId`, and pushes it to ACR. The same tag is passed to Helm so every deployment is traceable.
3. **Deploy UAT:** The pipeline connects to AKS, ensures the Key Vault CSI addon and its CRD are ready, installs NGINX Ingress, applies the NetworkPolicy, and deploys the Helm chart to the `uat` namespace.
4. **Deploy production green:** Green is installed beside blue. The pipeline waits for ready pods and checks pods, endpoints, Ingress, NGINX, the Load Balancer IP, and `/healthz`. Blue continues serving traffic during validation.
5. **Switch or roll back:** The production Service selects pods using the `version` label. The swap changes the selector from blue to green. Rollback changes it back to blue, so rollback does not require rebuilding the image.
6. **Route traffic:** `Internet -> Azure Standard Load Balancer -> NGINX Ingress -> Kubernetes Ingress -> ClusterIP Service -> application pods`.
7. **Secure and operate:** Workload identity and the Secrets Store CSI driver mount the Key Vault `tls-cert` under `/mnt/secrets-store`. Probes, resource limits, HPA, PDB, RBAC, NetworkPolicy, ResourceQuota, Azure Monitor, Log Analytics, events, logs, and `kubectl top` support reliability and diagnosis.

The troubleshooting method is:

```text
Observe -> Isolate the failing layer -> Apply a reversible fix
	-> Verify health and traffic -> Document prevention
```

For example, when external NGINX traffic failed, I tested routing from inside the NGINX pod first. That separated application health from Load Balancer reachability. I then corrected the NetworkPolicy to allow the `ingress-nginx` namespace, configured `externalTrafficPolicy: Local`, and verified an HTTP 200 health response.

## Ready-to-Say Project Answer

“I built a production-style CI/CD solution for a containerized application on AKS. Terraform provisioned AKS, ACR, Key Vault, Azure CNI networking, workload identity, and monitoring. I separated infrastructure delivery from application delivery in Azure DevOps. The infrastructure pipeline generated a Terraform plan, published it for review, and applied the approved plan artifact. The application pipeline built a Docker image tagged with the build ID, pushed it to ACR, and deployed it with Helm.

The application was deployed to UAT first. In production I used blue-green deployment: green was deployed and validated beside blue while the Service still selected blue. After approval, the pipeline changed the Service selector to green; rollback changed it back to blue. NGINX Ingress, exposed through an Azure Standard Load Balancer, routed traffic to the selected pods. I used workload identity and the Key Vault CSI driver instead of static credentials, plus probes, HPA, PDB, NetworkPolicy, RBAC, and ResourceQuota. I diagnosed pipeline, Helm, NetworkPolicy, and Load Balancer health-check issues using logs, events, endpoints, metrics, and in-cluster routing. For a real production service, I would add image signing, digest pinning, more automated tests, SLO-based rollback, and disaster recovery testing.”

## How to Perform Well

For every answer, explain the goal, design choice, implementation, verification, and tradeoff. For incident questions, describe the symptom, checks, root cause, fix, and prevention. Be accurate: NGINX is the active ingress architecture, while Application Gateway is only a documented alternative; this is a production-style project, not a claim of operating a large-scale production service.

## Architecture and CI/CD

### 1. Walk me through the complete deployment flow.

**Answer:** A code change triggers Azure DevOps. The infrastructure pipeline runs `terraform init` and `terraform plan`, publishes the plan artifact, and applies that exact reviewed plan after an approval gate. The application pipeline builds a Docker image tagged with the Azure DevOps Build ID, pushes it to ACR, deploys to UAT with Helm, then deploys a green version alongside blue in production. Readiness and routing checks run before a manual approval stage patches the production Service selector to green. A separate manual stage can patch it back to blue.

### 2. Why did you separate the infrastructure and application pipelines?

**Answer:** Infrastructure changes have a different review, approval, and risk profile from application releases. Separating them avoids provisioning Azure resources on every application deployment, gives infrastructure changes a plan and approval boundary, and lets application teams release independently once the platform exists.

### 3. Why publish and apply a Terraform plan artifact?

**Answer:** Planning and applying separately improves reviewability. The apply stage uses the saved `tfplan`, so it applies the reviewed result rather than recalculating a potentially different plan. The artifact also provides an auditable record of the intended infrastructure change.

### 4. How did you make image versions traceable?

**Answer:** The image tag uses `$(Build.BuildId)`. The same tag is passed to Helm during deployment, so a running pod can be traced to a specific pipeline run. I avoid using `latest` for controlled releases because it is mutable and makes rollback and diagnosis harder.

### 5. What approvals exist in the delivery process?

**Answer:** The pipeline uses approval-backed Azure DevOps environments for infrastructure apply, UAT, production green deployment, production traffic swap, and rollback. This separates automated validation from the human decision to promote or change production traffic.

### 6. What happens if a deployment fails readiness checks?

**Answer:** The deployment should not be promoted. I inspect pod status, pod events, logs, image pull status, probe configuration, Service endpoints, and the mounted secret volume. Because the Service selector only points to the active version, an unready green version should not receive production traffic.

### 7. Why use Helm instead of raw manifests?

**Answer:** Helm gives the application a reusable package with environment-specific values. The same chart is used for UAT and production while values and pipeline overrides control image, host, version, autoscaling, and Azure integration settings. `helm upgrade --install` makes deployment repeatable and idempotent.

### 8. How would you improve this pipeline for a larger team?

**Answer:** I would add automated unit, container, Helm template, security, and integration tests before deployment; use immutable image digests; add deployment telemetry and automatic rollback criteria; pin action and Helm chart versions; and use reusable YAML templates to reduce duplication.

## Terraform and Azure

### 9. What does Terraform provision in this project?

**Answer:** It provisions the resource group, AKS, ACR, Key Vault, Azure CNI networking configuration, workload identity integration, monitoring and Log Analytics integration, optional role assignments, Defender for Containers pricing, and an optional CPU alert with an action group. Modules separate ACR, AKS, Key Vault, and Application Gateway concerns.

### 10. How is Terraform state managed?

**Answer:** State is stored remotely in an Azure Storage backend. The pipeline runs `terraform init` with the backend configuration before planning or applying. Remote state supports collaboration and locking. A force-unlock operation is guarded by checking that the requested lock ID matches the actual backend lock.

### 11. What would you do when Terraform reports a state lock?

**Answer:** First I confirm whether another pipeline or operator is running. I inspect the lock metadata and pipeline history. I only force-unlock if the lock is stale and the lock ID matches the actual backend lock. I would never blindly use `terraform force-unlock` during an active apply.

### 12. Why were role assignments made optional?

**Answer:** Creating role assignments requires elevated permissions such as User Access Administrator or Owner. Making them opt-in lets an appropriately authorized bootstrap run create them, while a service principal with only normal infrastructure permissions can run without failing on role-assignment creation. Required permissions still need to be documented and verified.

### 13. How would you secure Terraform secrets and variables?

**Answer:** I would keep secrets out of Git and plan artifacts, use secret variables or Key Vault-backed variable integration, restrict service connection permissions, use federated credentials where possible, and prevent secrets from appearing in command output. I would also review Terraform state because sensitive values can be present there.

### 14. Why choose Azure CNI?

**Answer:** Azure CNI gives pods Azure VNet IP addresses and integrates directly with Azure networking and security controls. The tradeoff is higher subnet IP consumption and more planning. For a very large cluster I would evaluate Azure CNI Overlay to reduce VNet IP pressure.

### 15. Why use NGINX Ingress instead of Application Gateway?

**Answer:** NGINX is Kubernetes-native, portable, and makes Ingress, Service, and NetworkPolicy behavior clear for this project. Application Gateway with AGIC is a valid Azure-managed alternative, but it changes the controller, identity, routing, and troubleshooting model. In this implementation, NGINX plus an Azure Load Balancer is the active path.

## Docker, Kubernetes, and Helm

### 16. How does traffic reach the application?

**Answer:** Internet traffic reaches the Azure Standard Load Balancer service for NGINX Ingress. NGINX matches the Host and path in the Kubernetes Ingress resource, forwards to the application ClusterIP Service, and the Service selects pods by application and version labels.

### 17. Explain the blue-green deployment implementation.

**Answer:** Blue and green Deployments have different `version` labels. The production Service selector includes the active version. Green is installed and validated while blue continues serving traffic. The swap changes only the Service selector from blue to green. Rollback changes the selector back to blue, which is fast because blue remains available.

### 18. What are the limitations of this blue-green approach?

**Answer:** It temporarily runs both versions, so it costs more resources. It requires compatible data and API changes, careful handling of background workers, and verification that both versions coexist safely. The current rollback stage patches the selector manually; a mature design would record the previous version and automate rollback based on post-deployment metrics.

### 19. What is the difference between a Service and an Ingress?

**Answer:** A Service provides stable internal discovery and load balancing to selected pods. An Ingress describes HTTP or HTTPS routing rules such as host and path. An Ingress controller, NGINX here, watches those rules and implements external routing.

### 20. What do readiness and liveness probes do?

**Answer:** Readiness controls whether a pod receives Service traffic. Liveness determines whether Kubernetes should restart a container that is stuck or unhealthy. The application exposes `/healthz` on port 8080, and both probes use that endpoint with different timings.

### 21. What are requests and limits?

**Answer:** Requests are used for scheduling and represent the resources a pod needs. Limits cap resource usage. This chart requests 100m CPU and 128 MiB memory, with limits of 250m CPU and 256 MiB memory. Poor values can cause pending pods, throttling, or OOM kills.

### 22. How does the HPA work here?

**Answer:** Production enables autoscaling, while UAT disables it to avoid unnecessary complexity during testing. HPA requires resource requests and a working metrics source. I would verify it with `kubectl get hpa` and `kubectl describe hpa`.

### 23. What is the purpose of a PDB?

**Answer:** A PodDisruptionBudget limits voluntary disruption, such as node maintenance, so too many replicas are not unavailable at once. It does not prevent crashes or guarantee availability if there are too few replicas.

### 24. How would you debug a Helm deployment failure?

**Answer:** I would run `helm lint`, `helm template` with the exact values, and inspect the rendered YAML, CRD dependencies, namespace, and Kubernetes events. In this project, the SecretProviderClass template was guarded because the CRD might not exist yet, and HPA was disabled in UAT because its values were incomplete.

### 25. What happens when a pod is stuck in `ImagePullBackOff`?

**Answer:** I inspect pod events, confirm the repository and immutable tag, test ACR access, verify the AKS kubelet identity has `AcrPull`, and check whether the image exists. I also verify the registry name and node connectivity.

### 26. How would you diagnose `CrashLoopBackOff`?

**Answer:** I check current and previous logs, events, exit code, probe failures, mounted files, environment variables, resource limits, and recent image changes. I compare the failing version with the known-good version and confirm the application binds to port 8080 and serves `/healthz`.

## Security and Identity

### 27. How does the application access Key Vault?

**Answer:** AKS OIDC workload identity maps a Kubernetes ServiceAccount to a user-assigned managed identity. The identity has the required Key Vault role, and the Secrets Store CSI driver mounts the `tls-cert` secret as a file under `/mnt/secrets-store`. No client secret is stored in Git or Helm values.

### 28. What would you check if the Key Vault volume does not mount?

**Answer:** I check the SecretProviderClass, CSI provider and addon status, pod events, ServiceAccount annotations, workload identity labels, tenant ID, client ID, vault name, Key Vault role assignment, OIDC issuer, and whether the secret exists.

### 29. What does the NetworkPolicy protect?

**Answer:** It restricts pod ingress to explicitly allowed sources and ports. The application must allow traffic from the `ingress-nginx` namespace on TCP 8080. A previous policy allowed only `kube-system`, so NGINX could not reach the application. The fix allowed the actual ingress namespace.

### 30. How would you investigate a Kubernetes RBAC lockout?

**Answer:** I reproduce the denied command with `kubectl auth can-i`, identify the user or ServiceAccount, inspect Role, ClusterRole, and bindings, and check namespace scope. I grant the smallest required permission and retest the original operation.

### 31. Why use Kubernetes RBAC as well as Azure RBAC?

**Answer:** Azure RBAC controls access to Azure resources such as AKS, ACR, and Key Vault. Kubernetes RBAC controls actions inside the cluster, such as reading pods or modifying Deployments. They protect different control planes.

## Observability and Incident Response

### 32. What monitoring did you implement?

**Answer:** Terraform enables Azure Monitor integration and a Log Analytics workspace. An optional Azure Monitor metric alert detects average AKS node CPU above 80 percent over a 15-minute window and sends notifications through an action group. I also use ContainerLogV2, KubePodInventory, Kubernetes events, and `kubectl top`.

### 33. How would you investigate high node CPU?

**Answer:** I confirm the alert and time window, inspect node and pod usage with `kubectl top`, identify workloads causing pressure, check HPA behavior and limits, inspect recent deployments, and review logs. I then tune or scale based on evidence and verify recovery.

### 34. How would you investigate an external 502 or unreachable Load Balancer IP?

**Answer:** I work from inside out: pod readiness, Service selectors, endpoints, Ingress rules, NGINX controller health, Load Balancer service status, and DNS or Host header. I test routing from inside the NGINX pod first. A 200 response there isolates the remaining problem to external reachability, DNS, or source networking.

### 35. Why was `externalTrafficPolicy: Local` important?

**Answer:** It lets the Azure Load Balancer use a Kubernetes node health-check path suitable for locally hosted NGINX endpoints instead of depending on a host-dependent default route. After recreating the service, I rechecked the external IP because it can change.

### 36. What is your general incident response process?

**Answer:** I define impact and start time, observe metrics and symptoms, inspect events and logs, isolate the failing layer, apply the smallest reversible repair, verify health and user traffic, and document the root cause and prevention. I preserve evidence and avoid unrelated changes before validating the first hypothesis.

### 37. How would you diagnose an OOMKilled pod?

**Answer:** I inspect the termination reason and previous logs, compare memory usage with requests and limits, use `kubectl top`, check for leaks or large requests, and review node pressure. A temporary limit increase may restore service, but the permanent fix should address application behavior and resource sizing.

### 38. How would you handle node pressure?

**Answer:** I inspect node conditions, allocatable resources, pod requests, disk usage, eviction events, and workload usage. I identify the pressure type, repair capacity or scheduling constraints, and verify that evictions stop.

### 39. How would you handle certificate expiry?

**Answer:** I identify where the certificate is stored and consumed, check the mounted secret and expiry, confirm Key Vault and CSI rotation, renew it through the approved process, and verify the mounted file and external TLS response. I would add expiry monitoring before the next renewal window.

### 40. What evidence do you capture after a release or incident?

**Answer:** I capture sanitized output for nodes, pods, Deployments, Services, endpoints, Ingress, NetworkPolicies, events, HPA, PDB, workload identity, and CSI mounts. I also record pipeline approvals, image tag, traffic selector, monitoring results, and smoke-test output while removing secrets.

## Behavioral and Senior-Level Questions

### 41. What was the most difficult issue you solved?

**Answer:** The NGINX route was externally unhealthy even though the application existed. I separated the path into layers, confirmed in-cluster routing, inspected NetworkPolicy and Load Balancer behavior, allowed traffic from the ingress-nginx namespace, configured `externalTrafficPolicy: Local`, recreated the unhealthy service, and verified an HTTP 200 response. The lesson was to isolate the failing layer instead of assuming the application was broken.

### 42. Tell me about a pipeline failure and your fix.

**Answer:** The hosted agent needed Terraform installed and initialized. I added explicit Terraform installation and `terraform init` steps. I also published the plan in the plan stage and downloaded it before apply, making the pipeline self-contained and ensuring apply used the reviewed plan.

### 43. How do you balance speed and safety in deployments?

**Answer:** I automate repeatable checks and deployment steps, but keep approvals at infrastructure, production deployment, traffic swap, and rollback boundaries. Blue-green deployment reduces exposure because the new version is validated before becoming active. Immutable tags and health checks make decisions faster and safer.

### 44. What would you improve first if this became a real production service?

**Answer:** I would add automated tests and security scanning, image signing and digest pinning, private networking where appropriate, centralized dashboards and SLOs, automated rollback based on metrics, stronger secret rotation validation, multi-zone testing, and disaster recovery procedures.

### 45. What did you learn from debugging this project?

**Answer:** Many deployment failures occur at boundaries: pipeline tooling, Terraform state, Helm values, CRDs, identity, policy, Service selectors, ingress, and cloud Load Balancer health checks. A repeatable observe-isolate-fix-verify process is more reliable than changing several layers at once.

## Rapid-Fire Questions

| Question | Short answer |
|---|---|
| What is ACR? | Azure Container Registry, used to store and distribute images. |
| What is AKS? | Azure-managed Kubernetes service. |
| What is Helm? | A package and release manager for Kubernetes. |
| What is a ClusterIP? | An internal virtual IP for selected pods. |
| What does `kubectl get endpoints` show? | Pod IPs currently selected behind a Service. |
| Why use `set -euo pipefail`? | It fails scripts on command, unset-variable, or pipeline errors. |
| Why use namespaces? | To isolate UAT and production resources and permissions. |
| What is an immutable release? | One referencing a fixed artifact, ideally an image digest. |
| What is the active ingress path? | NGINX Ingress exposed by an Azure Standard Load Balancer. |
| Is Application Gateway active here? | No; it is a documented alternative. |
| Where is the TLS secret mounted? | `/mnt/secrets-store` through the CSI driver. |
| How is rollback performed? | Patch the production Service selector back to `version: blue`. |

## Interview Rules for This Project

1. Say what you personally implemented, tested, and observed.
2. Distinguish active architecture from alternatives: NGINX is active; Application Gateway is not.
3. Explain the failure, evidence, root cause, fix, and verification for each troubleshooting story.
4. Do not claim zero downtime without explaining probes, capacity, compatible data changes, and traffic validation.
5. Mention limitations honestly: this is a production-style practice project, and rollback and monitoring can still be automated further.
# Workflow Architecture Diagram

```mermaid
flowchart LR
    Dev[Developer / Operator] --> Repo[Git Repository]
    Repo --> Pip[Azure DevOps Pipeline]

    Pip -->|Terraform Plan| TF[Terraform + AzureRM]
    TF --> RG[Resource Group]
    TF --> ACR[Azure Container Registry]
    TF --> KV[Azure Key Vault]
    TF --> AKS[Azure Kubernetes Service]
    TF --> POL[Azure Policy + Defender for Cloud]

    ACR --> IMG[Container Image]
    IMG --> AKS
    KV --> AKS

    Pip -->|Build & Push| ACR
    Pip -->|Deploy UAT| AKS
    Pip -->|Deploy Prod Green| AKS
    Pip -->|Swap Traffic| AKS
    Pip -->|Rollback| AKS

    AKS --> NSUAT[Namespace: uat]
    AKS --> NSPROD[Namespace: production]

    NSUAT --> APPUAT[Helm Release: uat]
    NSPROD --> APPPROD[Helm Release: production]

    APPPROD --> SVC[ClusterIP Service]
    SVC --> ING[NGINX Ingress Controller]
    ING --> LB[Azure LoadBalancer Service]

    APPUAT --> MON[Azure Monitor / Container Insights]
    APPPROD --> MON
```

## Flow Summary

1. A developer pushes changes to the repository.
2. Azure DevOps runs Terraform plan and apply through approval gates.
3. Terraform provisions AKS, ACR, Key Vault, workload identity, monitoring, Policy, and Defender settings.
4. The pipeline builds and pushes the application image to ACR.
5. Helm deploys NGINX ingress controller and the app into UAT and production namespaces on AKS.
6. The Azure Standard Load Balancer exposes NGINX, which routes traffic to the ClusterIP Service and workload.
7. Azure Monitor and Defender provide operational and security visibility.

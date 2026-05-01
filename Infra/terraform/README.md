# Infrastructure Automation with Terraform

This repository contains the Terraform configuration files used to provision a secure, private, and scalable infrastructure on Microsoft Azure. The architecture heavily relies on Private Endpoints to ensure that services are not accessible via the public internet.

## Architecture Overview

The Terraform configuration (`main.tf`) sets up the following Azure resources:

- **Resource Group**: A logical container for all the deployed resources.
- **Virtual Network (VNet)**: Provides a secure network backbone with dedicated subnets for:
  - SQL Database
  - Storage Accounts
  - Azure Kubernetes Service (AKS)
  - OCR (Computer Vision)
  - OpenAI
  - Private Endpoints (dedicated subnet with network policies disabled)
- **Network Security Groups (NSGs)**: Applied to subnets to tightly control inbound and outbound traffic, typically denying internet inbound traffic and allowing specific services.
- **Private DNS Zones**: Enables DNS resolution for resources accessed via Private Endpoints.
- **Azure SQL Server & Database**: A private SQL Server instance, accessed entirely via a Private Endpoint.
- **Storage Accounts**: Provisioned securely with Blob, File, Queue, and Table services. Includes seeding capability and Private Endpoints for all sub-resources.
- **Azure Kubernetes Service (AKS)**: A fully private cluster, with Role-Based Access Control (RBAC), Workload Identity, and Key Vault integration for secrets management.
- **Azure Cognitive Services**:
  - **OpenAI**: Provisioned privately with deployments for standard models and embeddings.
  - **Computer Vision (OCR)**: A private instance deployed for optical character recognition workloads.
- **Azure Key Vault**: Stores sensitive credentials (like SQL Admin Passwords and OCR keys) and is accessed via Private Endpoint. It grants the AKS cluster Secrets User access.
- **VNet Peering**: Supports peering from the newly created spoke VNet to an existing client Hub VNet (conditionally deployed).

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) installed.
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated.
- An active Azure Subscription.

## Deployment Steps

Based on the operations history, follow these steps to initialize and deploy the infrastructure safely.

### 1. Authenticate and Set Subscription

Log in to your Azure account and set your target subscription:

```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 2. Set Required Environment Variables

To protect sensitive information, pass them as environment variables rather than hardcoding them in the configuration files:

```powershell
$env:TF_VAR_subscription_id="<SUBSCRIPTION_ID>"
$env:TF_VAR_kv_admin_object_id="<KV_ADMIN_OBJECT_ID>"
$env:TF_VAR_sql_admin_password="<SQL_ADMIN_PASSWORD>"
```

### 3. Initialize and Validate the Configuration

Navigate to the `Infra` directory and run standard Terraform validation steps:

```powershell
cd .\Infra\
terraform init
terraform fmt -recursive
terraform validate
```

### 4. Plan the Deployment

Generate and save an execution plan to review the changes before applying them:

```powershell
terraform plan -out plan.out
```

### 5. Apply the Infrastructure

Execute the plan. The `--parallelism` flag can be adjusted depending on resource provisioning limits:

```powershell
terraform apply --parallelism=5
```

### 6. Working with Existing Resources (Import)

If you need to manage resources that were created outside of Terraform or lost from the state, you can import them. Examples of importing Private DNS Zone Virtual Network Links:

```powershell
terraform import azurerm_private_dns_zone_virtual_network_link.blob_dns_link /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/...
terraform import azurerm_private_dns_zone_virtual_network_link.table_dns_link /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/...
terraform import azurerm_private_dns_zone_virtual_network_link.cognitive_dns_link /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/...
terraform import azurerm_private_dns_zone_virtual_network_link.kv_dns_link /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/...
```

### 7. Managing State and Workspaces

Terraform state commands and workspaces are useful for isolation and fixing issues:

```powershell
# Pull remote state locally
terraform state pull > terraform.tfstate

# View all outputs in JSON format
terraform output -json

# Create and switch to a new workspace (e.g., dev)
terraform workspace new dev
terraform workspace list

# Remove specific items from state (if needed to recreate or ignore)
terraform state rm azurerm_logic_app_workflow.logic_apps
```

### 8. Cleanup and Destruction

If specific resources need to be deleted without destroying the whole environment:

```powershell
terraform destroy -target="azurerm_kubernetes_cluster.aks"
```

To destroy the entire infrastructure:

```powershell
terraform destroy
```

## Security Best Practices

- **No Public Endpoints:** Resources like AKS API Server, SQL Server, Storage Accounts, and Cognitive Services have public access disabled and utilize Azure Private Endpoints.
- **Sensitive Variables:** Never commit `terraform.tfvars` containing secrets or the `terraform.tfstate` file to version control.
- **Identity & Access Management (IAM):** Managed Identities and specific Role Assignments are heavily utilized (e.g., AKS getting Network Contributor, Key Vault Secrets User roles) to follow the principle of least privilege.

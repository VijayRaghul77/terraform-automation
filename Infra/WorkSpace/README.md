# Azure Terraform Workspace Practice

This repository contains a hands-on guide and configuration for managing Azure infrastructure using **Terraform Workspaces**. It demonstrates environment isolation, resource migration from the Azure Portal, and best practices for state management.

## 🚀 Key Features
- **Workspace Isolation**: Separate state files for `dev`, `prod`, and other environments.
- **Resource Migration**: Guided process for importing existing Azure Web Apps and Service Plans into Terraform.
- **Dynamic Configuration**: Using `terraform.workspace` to dynamically name resources based on the active environment.

## 📁 Repository Analysis

Understanding the files in this directory is key to mastering Terraform. Here is a breakdown of every component:

### Core Configuration Files
*   **`main.tf`**: The "Source of Truth" for your infrastructure. It contains the logic for creating the Azure Resource Group, App Service Plan, and Linux Web App. It uses interpolation (`${terraform.workspace}`) to keep resources unique across environments.
*   **`README.md`**: This documentation file, explaining the project workflow and structure.

### Internal Terraform Metadata (Hidden)
*   **`.terraform/`**: Created during `terraform init`. It stores the downloaded provider plugins (like `azurerm`) and internal metadata about your environment.
    *   `providers/`: Contains the executable binaries for the Azure provider.
    *   `environment`: A small file that keeps track of which workspace is currently active.
*   **`.terraform.lock.hcl`**: The "Lock File". It records the exact version and checksum of the providers used. This ensures that everyone working on this project (or you, in the future) uses the exact same provider version for stability.

### State Management
*   **`terraform.tfstate.d/`**: The core of Workspace management.
    *   **`dev/`**: Contains the state file specifically for the development environment.
    *   **`prod/`**: Contains the state file specifically for the production environment.
    *   **`*.tfstate`**: The JSON snapshot of your real-world infrastructure.
    *   **`*.tfstate.backup`**: A backup created automatically before every `apply` operation to prevent data loss.

---

## 📂 Project Structure
- `main.tf`: Core configuration containing Resource Groups, App Service Plans, and Linux Web Apps.
- `terraform.tfstate.d/`: Local directory where workspace-specific state files are stored.

---

## 🛠️ Usage Guide

### 1. Workspace Management
Workspaces allow you to manage multiple environments (Dev, Stage, Prod) using the same code.

```bash
# List all workspaces
terraform workspace list

# Create and switch to a new environment
terraform workspace new dev

# Switch between existing environments
terraform workspace select prod

# Show current active workspace
terraform workspace show
```

### 2. Migrating Existing Azure Resources
To migrate resources created in the Azure Portal into this Terraform project:

1. **Define Import Blocks**: Add `import` blocks to your code with the Azure Resource IDs.
2. **Generate Configuration**: Use the experimental generation flag:
   ```bash
   terraform plan -generate-config-out=generated.tf
   ```
3. **Apply the Import**: Run the apply command to pull the resources into your state:
   ```bash
   terraform apply
   ```

### 3. Deployment Workflow
```bash
# Initialize the backend and providers
terraform init

# Preview changes (safe for practice)
terraform plan -lock=false

# Apply changes to your Azure Subscription
terraform apply -auto-approve

# Clean up resources
terraform destroy
```

---

## 📝 Commands History Reference
Based on recent operations, the following sequence is recommended for practice:
1. `terraform init`
2. `terraform workspace new dev`
3. `terraform plan` (observes `rg-workspace-practice-dev` creation)
4. `terraform workspace new prod`
5. `terraform plan` (observes `rg-workspace-practice-prod` creation)
6. `terraform workspace select dev`

---

## ⚠️ Important Notes
- **State Locking**: On Windows systems, you may encounter file locking issues during rapid command execution. Use the `-lock=false` flag if you are practicing locally and no other users are modifying the state.
- **Provider Limits**: Some newer Azure features (like Python 3.14) may not be immediately supported by the Terraform provider. Always check for the latest `azurerm` version.

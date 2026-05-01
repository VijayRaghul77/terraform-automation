# Lab: Terraform State Manipulation in Azure

This lab provides hands-on experience with advanced Terraform state management. We practiced importing, moving, untracking, and refactoring resources in an active Azure environment.

## 🛠️ Prerequisites
- Azure CLI authenticated (`az login`)
- Subscription ID: `Subscription_ID`

## 📖 Scenarios & Workflow

### 1. Import Existing Resource
Bring a manually created Azure resource under Terraform control.
- **Manual Creation**:
  ```powershell
  . './setup_import.ps1' # Creates rg-manual-resource
  ```
- **Terraform Import**:
  ```powershell
  terraform import azurerm_resource_group.manual /subscriptions/################/resourceGroups/rg-manual-resource
  ```

### 2. Rename a Resource (State Move)
Rename a resource label in your `.tf` files without triggering a destroy/recreate cycle.
- **Action**: Rename `azurerm_resource_group.demo` to `azurerm_resource_group.final_rg`.
- **Command**:
  ```powershell
  terraform state mv azurerm_resource_group.demo azurerm_resource_group.final_rg
  ```

### 3. Untrack a Resource (State RM)
Stop managing a resource in Terraform while keeping it alive in Azure.
- **Command**:
  ```powershell
  terraform state rm azurerm_resource_group.manual
  ```

### 4. Refactor to Module
Move resources from the root configuration into a reusable module.
- **Action**: Move `final_rg` into `module.my_rg`.
- **Command**:
  ```powershell
  terraform state mv azurerm_resource_group.final_rg module.my_rg.azurerm_resource_group.this
  ```

---

## 📜 Session History & Verified Commands
The following commands were successfully executed in this session:

| ID | Command | Description |
| :--- | :--- | :--- |
| 1 | `. '.\setup_import.ps1'` | Initial environment setup. |
| 2 | `terraform import ...` | Imported `rg-manual-resource`. |
| 3 | `terraform state mv ...` | Renamed `demo` to `final_rg`. |
| 4 | `terraform state list` | Verified resources in state. |
| 5 | `terraform init` | Initialized backend and providers. |
| 6 | `terraform plan` | Verified configuration parity. |
| 7 | `terraform apply` | Applied changes to Azure. |
| 8 | `terraform destroy` | Cleaned up the lab environment. |

## 🔍 State Inspection Tips
- `terraform state list`: List all resources in the current state file.
- `terraform state show <resource_path>`: Show detailed attributes of a specific resource in state.

---
*Last Updated: 2026-05-02*

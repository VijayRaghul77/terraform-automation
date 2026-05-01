# Terraform Automation Lab

This repository contains a collection of Terraform projects and labs for automating Azure infrastructure. It covers various aspects from basic resource deployment to advanced state management and workspace isolation.

## 📂 Repository Structure

| Directory | Description |
| :--- | :--- |
| **[Infra/](./Infra/)** | Parent directory for all infrastructure projects. |
| **[Infra/statemanipulation/](./Infra/statemanipulation/)** | Hands-on lab for `terraform import`, `state mv`, and `state rm`. |
| **[Infra/WorkSpace/](./Infra/WorkSpace/)** | Practice for Terraform Workspaces (dev, prod) and environment isolation. |
| **[Infra/terraform/](./Infra/terraform/)** | Core infrastructure templates and seed data examples. |

## 🚀 Getting Started

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/VijayRaghul77/terraform-automation.git
    ```
2.  **Azure Login**:
    ```bash
    az login
    ```
3.  **Choose a Lab**:
    Navigate to any subdirectory and follow the local `README.md`.

## 🛠️ Best Practices Implemented
- **.gitignore**: Prevents tracking of large binaries (`.terraform/`) and sensitive state files (`*.tfstate`).
- **Modularization**: Example of refactoring flat code into reusable modules.
- **State Management**: Practical examples of manual state manipulation.

---
*Maintained by Vijay Raghul*

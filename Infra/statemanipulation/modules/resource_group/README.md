# Resource Group Module

This is a simple, reusable Terraform module for managing Azure Resource Groups.

## 📋 Features
- Creates a standardized Azure Resource Group.
- Outputs the Resource Group ID for use in other modules.

## 📥 Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| **resource_group_name** | The name of the resource group. | `string` | n/a | Yes |
| **location** | The Azure region where the resource group will be created. | `string` | n/a | Yes |

## 📤 Outputs

| Name | Description |
| :--- | :--- |
| **id** | The full resource ID of the created Resource Group. |

## 💻 Usage Example

```hcl
module "my_rg" {
  source              = "./modules/resource_group"
  resource_group_name = "rg-example"
  location            = "East US"
}
```

---
*Used as part of the State Manipulation lab to demonstrate code refactoring and state migration.*

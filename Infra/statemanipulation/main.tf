terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "my_rg" {
  source              = "./modules/resource_group"
  resource_group_name = "rg-state-manipulation-demo"
  location            = "East US"
}

module "rg_demo" {
  source              = "./modules/resource_group"
  resource_group_name = "rg_demo"
  location            = "East US"
}
# # 

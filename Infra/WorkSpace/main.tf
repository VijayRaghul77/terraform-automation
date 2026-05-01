terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# The resource name will change dynamically based on the active workspace
resource "azurerm_resource_group" "practice" {
  name     = "rg-workspace-practice-${terraform.workspace}"
  location = "East US"
}

resource "azurerm_service_plan" "prpod" {
  name                = "ASP-rgworkspacepracticeprod-b3dd"
  resource_group_name = azurerm_resource_group.practice.name
  location            = "canadacentral"
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "prpod" {
  name                = "prpod"
  resource_group_name = azurerm_resource_group.practice.name
  location            = "canadacentral"
  service_plan_id     = azurerm_service_plan.prpod.id
  https_only          = true

  site_config {
    always_on           = false
    ftps_state          = "FtpsOnly"
    minimum_tls_version = "1.2"

    application_stack {
      python_version = "3.12"
    }
  }
}

output "current_workspace" {
  value = terraform.workspace
}

# ──────────────────────────────────────────────
# Core
# ──────────────────────────────────────────────
variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "The Azure Region to deploy resources"
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "environment" {
  description = "Environment tag (e.g., production, staging)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "dev"], var.environment)
    error_message = "environment must be one of: production, staging, dev."
  }
}

variable "tags" {
  description = "Standard tags applied to all resources"
  type        = map(string)
}

# ──────────────────────────────────────────────
# Network
# ──────────────────────────────────────────────
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet (must not overlap with hub or prohibited ranges)"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space :
      !can(regex("^10\\.0\\.", cidr)) &&
      !can(regex("^10\\.99\\.", cidr)) &&
      !can(regex("^10\\.41\\.", cidr))
    ])
    error_message = "VNet CIDR must not overlap with 10.0.0.0/16, 10.99.0.0/16, or 10.41.0.0/16."
  }
}

variable "subnets" {
  description = "Map of subnets to create (sql, storage, aks, ocr, openai)"
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}

variable "pe_subnet_name" {
  description = "Name of the Private Endpoint subnet"
  type        = string
  default     = "pe-subnet"
}

variable "pe_subnet_address_prefixes" {
  description = "CIDR for the Private Endpoint subnet"
  type        = list(string)
  default     = ["10.51.10.0/27"]
}

# ──────────────────────────────────────────────
# Hub VNet Peering
# ──────────────────────────────────────────────
variable "hub_vnet_id" {
  description = "Full resource ID of the client's hub VNet for peering. Leave empty to skip peering."
  type        = string
  default     = ""
}

variable "use_hub_gateway" {
  description = "Use the hub VNet's gateway (ExpressRoute/VPN) for on-prem connectivity"
  type        = bool
  default     = false
}

# ──────────────────────────────────────────────
# SQL
# ──────────────────────────────────────────────
variable "sql_server_name" {
  description = "Name of the Azure SQL Server"
  type        = string
}

variable "sql_admin_login" {
  description = "Administrator login for SQL Server"
  type        = string
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server (passed via Key Vault / env var)"
  type        = string
  sensitive   = true
}

variable "sql_databases" {
  description = "List of SQL Databases to create"
  type        = list(string)
}

variable "sql_sku_name" {
  description = "SKU for the SQL Database"
  type        = string
  default     = "S0"
}

# ──────────────────────────────────────────────
# Storage
# ──────────────────────────────────────────────
variable "storage_accounts" {
  description = "Map of storage accounts to create"
  type = map(object({
    name                     = string
    account_tier             = string
    account_replication_type = string
  }))
}

variable "storage_file_shares" {
  description = "List of file shares to create"
  type        = list(string)
}

variable "storage_queues" {
  description = "List of queues to create"
  type        = list(string)
}

variable "storage_tables" {
  description = "List of tables to create"
  type        = list(string)
}

variable "storage_seed_files" {
  description = "Map of files to upload to file shares"
  type = map(object({
    share_name  = string
    source_path = string
    file_name   = string
  }))
}

variable "storage_containers" {
  description = "List of blob containers to create"
  type        = list(string)
}

variable "storage_seed_blobs" {
  description = "Map of files to upload to blob containers"
  type = map(object({
    container_name = string
    source_path    = string
    blob_name      = string
    content_type   = string
  }))
}

# ──────────────────────────────────────────────
# AKS
# ──────────────────────────────────────────────
variable "aks_cluster_name" {
  description = "Name of the AKS Cluster"
  type        = string
}

variable "aks_dns_prefix" {
  description = "DNS Prefix for AKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to pin for the cluster and node pools"
  type        = string
  default     = "1.30"
}

variable "aks_node_pools" {
  description = "Map of additional (user) node pools with workload isolation support"
  type = map(object({
    name                = string
    vm_size             = string
    node_count          = optional(number)
    min_node_count      = optional(number)
    max_node_count      = optional(number)
    enable_auto_scaling = optional(bool, false)
    mode                = string
    zones               = optional(list(number), [1, 2, 3])
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
}

variable "aks_service_cidr" {
  description = "Service CIDR for AKS (must not overlap with VNet or hub)"
  type        = string
}

variable "aks_dns_service_ip" {
  description = "DNS Service IP for AKS (must be within aks_service_cidr)"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "aks_admin_group_object_ids" {
  description = "List of Azure AD group object IDs for AKS admin access"
  type        = list(string)
}

# ──────────────────────────────────────────────
# Cognitive Services
# ──────────────────────────────────────────────
variable "openai_account_name" {
  description = "Name of the OpenAI Cognitive Services Account"
  type        = string
}

variable "openai_location" {
  description = "Azure region for OpenAI (may differ from main location)"
  type        = string
}

variable "openai_sku_name" {
  description = "SKU for OpenAI"
  type        = string
  default     = "S0"
}

variable "openai_custom_subdomain" {
  description = "Custom subdomain name for OpenAI endpoint"
  type        = string
}

variable "ocr_account_name" {
  description = "Name of the OCR (ComputerVision) Cognitive Services Account"
  type        = string
}

variable "ocr_sku_name" {
  description = "SKU for OCR"
  type        = string
  default     = "S1"
}

# ──────────────────────────────────────────────
# Key Vault
# ──────────────────────────────────────────────
variable "key_vault_name" {
  description = "Name of the Azure Key Vault (globally unique, 3-24 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "kv_admin_object_id" {
  description = "Object ID (user or service principal) that gets Key Vault Administrator role"
  type        = string
}

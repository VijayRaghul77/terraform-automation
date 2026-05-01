# ──────────────────────────────────────────────
# SQL Outputs
# ──────────────────────────────────────────────
output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_databases" {
  description = "List of deployed SQL database names"
  value       = [for db in azurerm_mssql_database.sql_databases : db.name]
}

output "sql_connection_strings" {
  description = "Private connection strings for each SQL database"
  value = {
    for name, db in azurerm_mssql_database.sql_databases :
    name => "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${db.name};Persist Security Info=False;User ID=${var.sql_admin_login};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
  sensitive = true
}

output "sql_private_endpoint_ip" {
  description = "Private IP address of the SQL Private Endpoint"
  value       = azurerm_private_endpoint.sql_pe.private_service_connection[0].private_ip_address
}

# ──────────────────────────────────────────────
# Storage Outputs
# ──────────────────────────────────────────────
output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "storage_private_endpoint_ids" {
  description = "IDs of all storage Private Endpoints"
  value = {
    blob  = azurerm_private_endpoint.storage_blob_pe.id
    file  = azurerm_private_endpoint.storage_file_pe.id
    queue = azurerm_private_endpoint.storage_queue_pe.id
    table = azurerm_private_endpoint.storage_table_pe.id
  }
}

# ──────────────────────────────────────────────
# AKS Outputs
# ──────────────────────────────────────────────
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_private_fqdn" {
  description = "Private FQDN of the AKS API server (only reachable inside VNet)"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
  sensitive   = true
}

output "aks_api_server_url" {
  description = "AKS API server host (private)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "aks_kube_config_raw" {
  description = "Raw kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_identity_principal_id" {
  description = "Principal ID of the AKS SystemAssigned managed identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}


# ──────────────────────────────────────────────
# OpenAI Outputs
# ──────────────────────────────────────────────
output "openai_endpoint" {
  description = "Private endpoint URL for Azure OpenAI"
  value       = azurerm_cognitive_account.openai_account.endpoint
}

output "openai_key" {
  description = "Primary access key for Azure OpenAI"
  value       = azurerm_cognitive_account.openai_account.primary_access_key
  sensitive   = true
}

output "openai_private_endpoint_ip" {
  description = "Private IP of the OpenAI Private Endpoint"
  value       = azurerm_private_endpoint.openai_pe.private_service_connection[0].private_ip_address
}

# ──────────────────────────────────────────────
# OCR Outputs
# ──────────────────────────────────────────────
output "ocr_account_name" {
  description = "Name of the OCR Cognitive Services account"
  value       = azurerm_cognitive_account.ocr_account.name
}

output "ocr_endpoint" {
  description = "Private endpoint URL for OCR"
  value       = azurerm_cognitive_account.ocr_account.endpoint
}

output "ocr_key" {
  description = "Primary access key for OCR"
  value       = azurerm_cognitive_account.ocr_account.primary_access_key
  sensitive   = true
}

output "ocr_private_endpoint_ip" {
  description = "Private IP of the OCR Private Endpoint"
  value       = azurerm_private_endpoint.ocr_pe.private_service_connection[0].private_ip_address
}

# ──────────────────────────────────────────────
# Key Vault Outputs
# ──────────────────────────────────────────────
output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP of the Key Vault Private Endpoint"
  value       = azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address
}

# ──────────────────────────────────────────────
# Network Outputs
# ──────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the deployed resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "pe_subnet_id" {
  description = "Resource ID of the Private Endpoint subnet"
  value       = azurerm_subnet.pe_subnet.id
}

# ──────────────────────────────────────────────
# Peering Outputs (for client hand-off)
# ──────────────────────────────────────────────
output "spoke_vnet_id_for_hub_peering" {
  description = "Provide this VNet ID to the client to create the reverse Hub→Spoke peering"
  value       = azurerm_virtual_network.vnet.id
}

output "spoke_vnet_address_space" {
  description = "Address space of the spoke VNet — client needs this for route tables / firewall rules"
  value       = azurerm_virtual_network.vnet.address_space
}

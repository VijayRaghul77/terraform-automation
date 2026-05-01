
# ============================================================
# Resource Group
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ============================================================
# Virtual Network
# ============================================================
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# ============================================================
# Subnets
# ============================================================
resource "azurerm_subnet" "sql_subnet" {
  name                 = var.subnets["sql"].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnets["sql"].address_prefixes

  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_subnet" "storage_subnet" {
  name                 = var.subnets["storage"].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnets["storage"].address_prefixes

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = var.subnets["aks"].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnets["aks"].address_prefixes

  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "ocr_subnet" {
  name                 = var.subnets["ocr"].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnets["ocr"].address_prefixes
}

resource "azurerm_subnet" "openai_subnet" {
  name                 = var.subnets["openai"].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnets["openai"].address_prefixes
}

# Dedicated Private Endpoint subnet — network policies disabled (required for PEs)
resource "azurerm_subnet" "pe_subnet" {
  name                 = var.pe_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.pe_subnet_address_prefixes

  private_endpoint_network_policies = "Disabled"
}

# ============================================================
# Network Security Groups
# ============================================================

# --- SQL Subnet NSG ---
resource "azurerm_network_security_group" "sql_nsg" {
  name                = "nsg-sql-subnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-AKS-to-SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.subnets["aks"].address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "sql_nsg_assoc" {
  subnet_id                 = azurerm_subnet.sql_subnet.id
  network_security_group_id = azurerm_network_security_group.sql_nsg.id
}

# --- Storage Subnet NSG ---
resource "azurerm_network_security_group" "storage_nsg" {
  name                = "nsg-storage-subnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-AKS-to-Storage"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["445", "443"]
    source_address_prefix      = var.subnets["aks"].address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "storage_nsg_assoc" {
  subnet_id                 = azurerm_subnet.storage_subnet.id
  network_security_group_id = azurerm_network_security_group.storage_nsg.id
}

# --- AKS Subnet NSG ---
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nsg-aks-subnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-LB-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# ============================================================
# Private DNS Zones
# ============================================================

resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "sql-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_link" {
  name                  = "blob-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "file_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_dns_link" {
  name                  = "file-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "queue_dns" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue_dns_link" {
  name                  = "queue-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queue_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "table_dns" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_dns_link" {
  name                  = "table-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.table_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "cognitive_dns" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_dns_link" {
  name                  = "cognitive-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "openai_dns" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_dns_link" {
  name                  = "openai-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "kv-dns-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# ============================================================
# Azure SQL Server — PRIVATE
# ============================================================
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"

  # No public internet access — all traffic via Private Endpoint
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "sql_databases" {
  for_each  = toset(var.sql_databases)
  name      = each.value
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = var.sql_sku_name
  tags      = var.tags
}

# Private Endpoint — SQL
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "pe-${var.sql_server_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.sql_dns_link]
}

# ============================================================
# Storage Account — PRIVATE
# ============================================================
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_accounts["data"].name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_accounts["data"].account_tier
  account_replication_type = var.storage_accounts["data"].account_replication_type
  min_tls_version          = "TLS1_2"

  # Harden: disable anonymous/public blob access
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  # Only allow traffic from AKS and SQL subnets; everything else denied
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
    ip_rules       = [data.http.client_ip.response_body]
    virtual_network_subnet_ids = [
      azurerm_subnet.aks_subnet.id,
      azurerm_subnet.sql_subnet.id,
    ]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Storage File Shares
resource "azurerm_storage_share" "shares" {
  for_each             = toset(var.storage_file_shares)
  name                 = each.value
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 50
}

# Storage Queues
resource "azurerm_storage_queue" "queues" {
  for_each             = toset(var.storage_queues)
  name                 = each.value
  storage_account_name = azurerm_storage_account.storage.name
}

# Storage Tables
resource "azurerm_storage_table" "tables" {
  for_each             = toset(var.storage_tables)
  name                 = each.value
  storage_account_name = azurerm_storage_account.storage.name
}

# Storage Blob Containers (always private)
resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.storage_containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Storage Blob Seed Data
resource "azurerm_storage_blob" "seed_blobs" {
  for_each               = var.storage_seed_blobs
  name                   = each.value.blob_name
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.containers[each.value.container_name].name
  type                   = "Block"
  source                 = each.value.source_path
  content_type           = each.value.content_type
}

# Storage File Seed Data
resource "azurerm_storage_share_file" "seed_files" {
  for_each         = var.storage_seed_files
  name             = each.value.file_name
  storage_share_id = azurerm_storage_share.shares[each.value.share_name].id
  source           = each.value.source_path
}

# Private Endpoints — Storage (one per sub-resource)
resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = "pe-${var.storage_accounts["data"].name}-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.blob_dns_link]
}

resource "azurerm_private_endpoint" "storage_file_pe" {
  name                = "pe-${var.storage_accounts["data"].name}-file"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-file"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.file_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.file_dns_link]
}

resource "azurerm_private_endpoint" "storage_queue_pe" {
  name                = "pe-${var.storage_accounts["data"].name}-queue"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-queue"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "queue-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.queue_dns_link]
}

resource "azurerm_private_endpoint" "storage_table_pe" {
  name                = "pe-${var.storage_accounts["data"].name}-table"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-table"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "table-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.table_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.table_dns_link]
}

# ============================================================
# AKS Cluster — PRIVATE
# ============================================================
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.aks_cluster_name
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  dns_prefix                        = var.aks_dns_prefix
  kubernetes_version                = var.kubernetes_version
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  azure_policy_enabled              = true

  # Production SLA — 99.95% uptime guarantee
  sku_tier = "Standard"

  # Private cluster — API server not reachable from public internet
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false

  default_node_pool {
    name                 = "system"
    node_count           = 3
    vm_size              = "Standard_D2s_v5"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    orchestrator_version = var.kubernetes_version
    zones                = [1, 2, 3]

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.aks_service_cidr
    dns_service_ip    = var.aks_dns_service_ip
    outbound_type     = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.aks_admin_group_object_ids
    azure_rbac_enabled     = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }


  auto_scaler_profile {
    balance_similar_node_groups      = true
    max_graceful_termination_sec     = 600
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = 0.5
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [1, 2]
    }
  }

  tags = var.tags
}

# IAM: AKS identity needs Network Contributor to manage NICs in the VNet (Azure CNI)
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Additional Node Pools — with AZ spread, labels, and taints
resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
  for_each = var.aks_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  orchestrator_version  = var.kubernetes_version
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_node_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_node_count : null
  enable_auto_scaling   = each.value.enable_auto_scaling
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  mode                  = each.value.mode
  zones                 = each.value.zones
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# ============================================================
# Azure OpenAI — PRIVATE
# ============================================================
resource "azurerm_cognitive_account" "openai_account" {
  name                  = var.openai_account_name
  location              = var.openai_location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "OpenAI"
  sku_name              = var.openai_sku_name
  custom_subdomain_name = var.openai_custom_subdomain

  # Deny all public traffic
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "gpt51" {
  name                 = "gpt-5-1"
  cognitive_account_id = azurerm_cognitive_account.openai_account.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }

  scale {
    type     = "Standard"
    capacity = 10
  }
}

resource "azurerm_cognitive_deployment" "embeddings" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai_account.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type     = "Standard"
    capacity = 10
  }
}

# Private Endpoint — OpenAI
resource "azurerm_private_endpoint" "openai_pe" {
  name                = "pe-${var.openai_account_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-openai"
    private_connection_resource_id = azurerm_cognitive_account.openai_account.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "openai-dns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitive_dns.id,
      azurerm_private_dns_zone.openai_dns.id,
    ]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.cognitive_dns_link,
    azurerm_private_dns_zone_virtual_network_link.openai_dns_link,
  ]
}

# ============================================================
# OCR (ComputerVision) — PRIVATE
# ============================================================
resource "azurerm_cognitive_account" "ocr_account" {
  name                  = var.ocr_account_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "ComputerVision"
  sku_name              = var.ocr_sku_name
  custom_subdomain_name = var.ocr_account_name

  # Deny all public traffic
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Private Endpoint — OCR
resource "azurerm_private_endpoint" "ocr_pe" {
  name                = "pe-${var.ocr_account_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-ocr"
    private_connection_resource_id = azurerm_cognitive_account.ocr_account.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "ocr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cognitive_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.cognitive_dns_link]
}

data "http" "client_ip" {
  url = "https://api.ipify.org"
}

# ============================================================
# Azure Key Vault — Production Grade
# ============================================================
resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = true # Must be true to allow ip_rules

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [data.http.client_ip.response_body]
  }

  tags = var.tags
}

# Grant the pipeline / admin principal the Key Vault Administrator role
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.kv_admin_object_id
}

# Grant the AKS cluster managed identity Secrets User access
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Store SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store OCR credentials in Key Vault (E2-S02)
resource "azurerm_key_vault_secret" "ocr_primary_key" {
  name         = "ocr-primary-key"
  value        = azurerm_cognitive_account.ocr_account.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "ocr_endpoint" {
  name         = "ocr-endpoint"
  value        = azurerm_cognitive_account.ocr_account.endpoint
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Private Endpoint — Key Vault
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${var.key_vault_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.kv_dns_link]
}

# ============================================================
# ACR — Uses existing Botminds ACR in separate subscription
# ============================================================
# No ACR is created here. The cluster pulls images from the
# existing Botminds ACR. After deployment, grant AcrPull:
#
#   az role assignment create \
#     --assignee <AKS_KUBELET_IDENTITY_OBJECT_ID> \
#     --role AcrPull \
#     --scope <EXISTING_ACR_RESOURCE_ID>
#
# The kubelet identity object ID is output as aks_identity_principal_id.

# ============================================================
# VNet Peering — Spoke to Client Hub (conditional)
# ============================================================
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_vnet_id != "" ? 1 : 0

  name                         = "peer-spoke-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_hub_gateway
}



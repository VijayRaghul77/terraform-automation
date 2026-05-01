# ──────────────────────────────────────────────
# Core
# ──────────────────────────────────────────────
location            = "Canada Central"
resource_group_name = "clientname-production-rg"
environment         = "production"

tags = {
  owner           = "Beni"
  "Creation Date" = "2026-01-31"
  env             = "production"
  "Client Name"   = "Quebec"
}

# ──────────────────────────────────────────────
# Network — CIDR 10.51.0.0/16
# Avoids prohibited ranges:
#   10.99.0.0/16, 10.41.0.0/16,
#   Hub VNet 10.41.16.0/21, AVD VNet 10.41.88.0/21
# ──────────────────────────────────────────────
vnet_name          = "clientname-prod-vnet"
vnet_address_space = ["10.51.0.0/16"]

subnets = {
  sql = {
    name             = "sql-subnet"
    address_prefixes = ["10.51.1.0/24"]
  }
  storage = {
    name             = "storage-subnet"
    address_prefixes = ["10.51.2.0/24"]
  }
  aks = {
    name             = "aks-subnet"
    address_prefixes = ["10.51.4.0/22"] # /22 = 1022 IPs — room for Azure CNI pod scaling
  }
  ocr = {
    name             = "ocr-subnet"
    address_prefixes = ["10.51.8.0/24"]
  }
  openai = {
    name             = "openai-subnet"
    address_prefixes = ["10.51.9.0/24"]
  }
}

# Dedicated Private Endpoint subnet
pe_subnet_name             = "pe-subnet"
pe_subnet_address_prefixes = ["10.51.10.0/27"]

# ──────────────────────────────────────────────
# Hub VNet Peering
# ──────────────────────────────────────────────
# The client must provide the full resource ID of their hub VNet.
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<name>
hub_vnet_id     = "" # REQUIRED — set via pipeline variable or override
use_hub_gateway = false

# ──────────────────────────────────────────────
# SQL
# ──────────────────────────────────────────────
# sql_admin_password must be supplied via pipeline variable group / TF_VAR_sql_admin_password env var
sql_server_name = "clientname-prod-sql"
sql_admin_login = "sqladmin"
sql_databases   = ["Quebec-db", "gitea-db"]
sql_sku_name    = "S0"

# ──────────────────────────────────────────────
# Storage — ZRS for production durability
# ──────────────────────────────────────────────
storage_accounts = {
  data = {
    name                     = "clientnamedata"
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }
  jupiter = {
    name                     = "clientnamejupiter"
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }
}

storage_file_shares = [
  "browser-logs",
  "chat-llm",
  "jobcleaner",
  "ml-experiments",
  "ml-logs",
  "ml-pretrained",
  "ml-transformer-cache",
  "ml-vectorcache",
  "opensearch",
  "platform-logs",
  "rpa-bots",
  "rpa-botszip"
]

storage_queues = [
  "pdfhandlerlive",
  "pdfhandlerhighlive",
  "pdfhandlerlowlive",
  "pdfpreprocessorlive",
  "pdfpreprocessorhighlive",
  "pdfpreprocessorlowlive",
  "documentrescorerlive",
  "documentrescorerhighlive",
  "documentrescorerlowlive",
  "vectordocumentingestionlive",
  "vectordocumentingestionhighlive",
  "vectordocumentingestionlowlive"
]

storage_tables = [
  "SkillTemplates",
  "IndependentQueue",
  "PlaformConfig"
]

storage_containers = [
  "models",
  "globalconfig"
]

storage_seed_files = {
  "SkillTemplates" = {
    share_name  = "platform-logs"
    source_path = "seed_data/SkillTemplates.csv"
    file_name   = "SkillTemplates.csv"
  },
  "IndependentQueue" = {
    share_name  = "platform-logs"
    source_path = "seed_data/IndependentQueue.csv"
    file_name   = "IndependentQueue.csv"
  },
  "PlaformConfig" = {
    share_name  = "platform-logs"
    source_path = "seed_data/PlaformConfig.csv"
    file_name   = "PlaformConfig.csv"
  }
}

storage_seed_blobs = {
  "model_tar" = {
    container_name = "models"
    source_path    = "seed_data/model-v1.tar.gz"
    blob_name      = "model-v1.tar.gz"
    content_type   = "application/x-gzip"
  },
  "config1" = {
    container_name = "globalconfig"
    source_path    = "seed_data/globalconfig.json"
    blob_name      = "globalconfig.json"
    content_type   = "application/json"
  },
  "config2" = {
    container_name = "globalconfig"
    source_path    = "seed_data/config2.json"
    blob_name      = "config2.json"
    content_type   = "application/json"
  },
  "config3" = {
    container_name = "globalconfig"
    source_path    = "seed_data/config3.json"
    blob_name      = "config3.json"
    content_type   = "application/json"
  }
}

# ──────────────────────────────────────────────
# AKS
# ──────────────────────────────────────────────
aks_cluster_name   = "clientnameprodaks"
aks_dns_prefix     = "clientnameprod"
kubernetes_version = "1.34"

aks_node_pools = {
  client = {
    name        = "client"
    vm_size     = "Standard_D8s_v5"
    node_count  = 1
    mode        = "User"
    zones       = [1, 2, 3]
    node_labels = { "workload" = "app" }
    node_taints = []
  }
  e864large = {
    name                = "e864large"
    vm_size             = "Standard_E8s_v5"
    enable_auto_scaling = true
    min_node_count      = 1
    max_node_count      = 2
    mode                = "User"
    zones               = [1, 2, 3]
    node_labels         = { "workload" = "ml" }
    node_taints         = []
  }
  stde8sv5 = {
    name                = "stde8sv5"
    vm_size             = "Standard_D8s_v5"
    enable_auto_scaling = true
    min_node_count      = 1
    max_node_count      = 2
    mode                = "User"
    zones               = [1, 2, 3]
    node_labels         = { "workload" = "general" }
    node_taints         = []
  }
  esdata = {
    name        = "esdata"
    vm_size     = "Standard_E4s_v5"
    node_count  = 2
    mode        = "User"
    zones       = [1, 2, 3]
    node_labels = { "workload" = "opensearch" }
    node_taints = ["workload=opensearch:NoSchedule"]
  }
}

aks_service_cidr           = "10.52.0.0/16"
aks_dns_service_ip         = "10.52.0.10"
tenant_id                  = "################################"
aks_admin_group_object_ids = ["################################"]

# ──────────────────────────────────────────────
# Cognitive Services
# ──────────────────────────────────────────────
openai_account_name     = "clientname-prod-openai"
openai_location         = "East US"
openai_sku_name         = "S0"
openai_custom_subdomain = "clientname-prod-ai"

ocr_account_name = "clientname-prod-ocr"
ocr_sku_name     = "S1"

# ──────────────────────────────────────────────
# Key Vault
# ──────────────────────────────────────────────
key_vault_name = "clientname-prod-kv"

# Object ID of the service principal or user that administers Key Vault
# Must be set — typically the Azure DevOps SP or a dedicated admin AAD group object ID
# kv_admin_object_id = "<SET_IN_PIPELINE_OR_OVERRIDE>"

# Title         : config.hcl
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/security/vault/config.hcl
# ----------------------------------------------------------------------------
# HashiCorp Vault configuration for local development and secret management

# --- Storage Backend ---------------------------------------------------------
# File storage backend for development (not for production)
storage "file" {
  path = "/opt/vault/data"
}

# Alternative: Consul storage backend (for production)
# storage "consul" {
#   address = "127.0.0.1:8500"
#   path    = "vault/"
# }

# Alternative: Integrated storage (Raft) for production
# storage "raft" {
#   path    = "/opt/vault/data"
#   node_id = "node1"
# }

# --- Listener Configuration --------------------------------------------------
# HTTP listener for development
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

# HTTPS listener for production
# listener "tcp" {
#   address       = "0.0.0.0:8200"
#   tls_cert_file = "/opt/vault/tls/tls.crt"
#   tls_key_file  = "/opt/vault/tls/tls.key"
#   tls_min_version = "tls12"
# }

# --- API Configuration -------------------------------------------------------
api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"

# --- UI Configuration --------------------------------------------------------
ui = true

# --- Logging Configuration ---------------------------------------------------
log_level = "Info"
log_format = "standard"
log_file = "/var/log/vault/vault.log"
log_rotate_duration = "24h"
log_rotate_max_files = 30

# --- Performance Configuration -----------------------------------------------
# Disable memory lock for development (enable for production)
disable_mlock = true

# Default lease TTL
default_lease_ttl = "768h"

# Maximum lease TTL
max_lease_ttl = "8760h"

# --- Cluster Configuration ---------------------------------------------------
cluster_name = "vault-dev"

# --- Seal Configuration ------------------------------------------------------
# Auto-unseal with cloud KMS (production)
# seal "awskms" {
#   region     = "us-west-2"
#   kms_key_id = "alias/vault-unseal-key"
# }

# seal "gcpckms" {
#   project     = "my-project"
#   region      = "global"
#   key_ring    = "vault-keyring"
#   crypto_key  = "vault-key"
# }

# seal "azurekeyvault" {
#   tenant_id      = "46646709-b63e-4747-be42-516edeaf1e14"
#   client_id      = "03dc33fc-16d9-4b77-8ba3-2d325c12ff56"
#   client_secret  = "DUJDS3..."
#   vault_name     = "hc-vault"
#   key_name       = "vault_key"
# }

# --- Plugin Directory -------------------------------------------------------
plugin_directory = "/opt/vault/plugins"

# --- Telemetry Configuration ------------------------------------------------
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
  
  # StatsD configuration
  # statsd_address = "127.0.0.1:8125"
  
  # Circonus configuration
  # circonus_api_token = ""
  # circonus_api_app = "vault"
  # circonus_api_url = "https://api.circonus.com/v2"
  # circonus_submission_interval = "10s"
  # circonus_submission_url = ""
  # circonus_check_id = ""
  # circonus_check_force_metric_activation = "false"
  # circonus_check_instance_id = ""
  # circonus_check_search_tag = ""
  # circonus_check_display_name = ""
  # circonus_check_tags = ""
  # circonus_broker_id = ""
  # circonus_broker_select_tag = ""
}

# --- Entropy Augmentation ---------------------------------------------------
entropy "seal" {
  mode = "augmentation"
}

# --- Cache Configuration ----------------------------------------------------
cache {
  # Use in-memory cache
  use_auto_auth_token = true
}

# --- Sentinel Configuration -------------------------------------------------
# sentinel {
#   additional_enabled_modules = []
# }

# --- HSM Configuration ------------------------------------------------------
# pkcs11 {
#   lib            = "/usr/lib/softhsm/libsofthsm2.so"
#   slot           = "0"
#   pin            = "1234"
#   key_label      = "vault-hsm-key"
#   hmac_key_label = "vault-hsm-hmac-key"
#   generate_key   = "true"
# }

# --- Development Settings ---------------------------------------------------
# Disable clustering for development
disable_clustering = true

# Disable performance standby for development
disable_performance_standby = true

# Disable indexing for development
disable_indexing = false

# Disable cache for development (not recommended)
disable_cache = false

# --- Security Headers -------------------------------------------------------
# Custom response headers
# raw_storage_endpoint = true
# introspection_endpoint = true

# --- License Configuration --------------------------------------------------
# license_path = "/opt/vault/license/vault.hclic"

# --- Replication Configuration ----------------------------------------------
# replication {
#   performance {
#     token = "..."
#   }
#   dr {
#     token = "..."
#   }
# }

# --- Transform Configuration ------------------------------------------------
# transform {
#   role "payments" {
#     transformations = ["card-number"]
#   }
# }

# --- Audit Device Configuration ---------------------------------------------
# Enable file audit device
# audit_device "file" {
#   file_path = "/var/log/vault/audit.log"
#   log_raw   = false
#   format    = "json"
# }

# Enable syslog audit device
# audit_device "syslog" {
#   facility = "AUTH"
#   tag      = "vault"
#   format   = "json"
# }

# --- Custom Configuration ---------------------------------------------------
# Custom configuration for specific use cases

# Development mode settings
# dev_mode = true
# dev_listen_address = "127.0.0.1:8200"
# dev_root_token_id = "myroot"

# High availability settings
# ha_storage "consul" {
#   address = "127.0.0.1:8500"
#   path    = "vault/"
# }

# Service registration
# service_registration "consul" {
#   address = "127.0.0.1:8500"
# }

# --- Environment-Specific Configuration ------------------------------------
# Load additional configuration based on environment
# This would typically be done through environment variables or separate files

# Development environment
# disable_mlock = true
# ui = true
# log_level = "Debug"

# Production environment
# disable_mlock = false
# ui = false
# log_level = "Info"

# --- Plugin Configuration ---------------------------------------------------
# Configure specific plugins

# Database secrets engine
# plugin "database" {
#   command = "vault-plugin-database-postgresql"
#   sha256 = "..."
# }

# Custom plugin
# plugin "my-custom-plugin" {
#   command = "my-custom-plugin"
#   sha256 = "..."
# }
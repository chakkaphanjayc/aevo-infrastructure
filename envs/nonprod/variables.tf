variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "environment" {
  type    = string
  default = "nonprod"
}

variable "database_tier" {
  type    = string
  default = "db-custom-2-7680"
}

variable "api_image" {
  type = string
}

variable "worker_image" {
  type = string
}

variable "worker_core_api_origin" {
  type        = string
  default     = ""
  description = "Core API origin reachable by the Background Worker for connection-probe result ingestion."

  validation {
    condition     = can(regex("^https://[^\\s]+$", trimspace(var.worker_core_api_origin)))
    error_message = "worker_core_api_origin must be a non-empty HTTPS origin."
  }
}

variable "worker_probe_targets" {
  type        = string
  default     = "[]"
  description = "JSON array of {appCode, baseUrl, healthPath?} probe targets for the Background Worker."
}

variable "accounts_api_origin" {
  type        = string
  default     = ""
  description = "Private Aevo Accounts origin used by Core API and the Admin authentication BFF."

  validation {
    condition     = can(regex("^https://[^\\s]+$", trimspace(var.accounts_api_origin)))
    error_message = "accounts_api_origin must be a non-empty HTTPS origin."
  }
}

variable "secret_names" {
  type    = set(string)
  default = ["core-api-database-url", "core-api-session-secret", "core-api-service-secret", "origin-signing-secret", "connection-probe-token", "worker-shared-secret", "accounts-service-secret", "feed-cursor-secret", "feed-event-worker-token"]
}
variable "enabled_services" {
  type = set(string)
  default = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "cloudtasks.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com",
    "sts.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

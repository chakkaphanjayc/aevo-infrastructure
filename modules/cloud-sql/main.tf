variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_17"
}

variable "tier" {
  type = string
}

variable "private_network" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}

resource "google_sql_database_instance" "primary" {
  name                = "aevo-${var.environment}-postgres"
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.private_network
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "aevo" {
  name     = "aevo"
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
}

output "connection_name" {
  value = google_sql_database_instance.primary.connection_name
}

output "instance_name" {
  value = google_sql_database_instance.primary.name
}

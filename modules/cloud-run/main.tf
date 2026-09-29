variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "api_image" {
  type = string
}

variable "worker_image" {
  type = string
}

variable "api_service_account" {
  type = string
}

variable "worker_service_account" {
  type = string
}

variable "worker_pubsub_topic" {
  type    = string
  default = ""
}

variable "worker_task_queue" {
  type    = string
  default = ""
}

variable "worker_core_api_origin" {
  type    = string
  default = ""
}

variable "worker_probe_targets" {
  type    = string
  default = "[]"
}

variable "vpc_connector_id" {
  type = string
}

variable "api_secret_ids" {
  type    = map(string)
  default = {}
}

variable "accounts_api_origin" {
  type        = string
  default     = ""
  description = "Private Aevo Accounts origin used by the Core API authentication BFF."
}

variable "worker_secret_ids" {
  type    = map(string)
  default = {}
}

resource "google_cloud_run_v2_service" "core_api" {
  name                = "aevo-core-api-${var.environment}"
  project             = var.project_id
  location            = var.region
  deletion_protection = var.environment == "production"

  template {
    service_account = var.api_service_account

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = var.environment == "production" ? 1 : 0
      max_instance_count = var.environment == "production" ? 20 : 4
    }

    containers {
      image = var.api_image
      ports {
        container_port = 8080
      }
      env {
        name  = "AEVO_ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "AEVO_IDENTITY_PLATFORM_PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "AEVO_PUBSUB_TOPIC"
        value = var.worker_pubsub_topic
      }
      env {
        name  = "AEVO_TASK_QUEUE"
        value = var.worker_task_queue
      }
      env {
        name  = "AEVO_REQUIRE_GATEWAY_SIGNATURE"
        value = var.environment == "production" ? "true" : "false"
      }
      env {
        name  = "AEVO_TRUSTED_GATEWAYS"
        value = "aevo-edge-gateway"
      }
      env {
        name  = "AEVO_ACCOUNTS_API_ORIGIN"
        value = var.accounts_api_origin
      }
      dynamic "env" {
        for_each = var.api_secret_ids
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service" "worker" {
  name                = "aevo-background-worker-${var.environment}"
  project             = var.project_id
  location            = var.region
  deletion_protection = var.environment == "production"

  template {
    service_account = var.worker_service_account

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = 0
      max_instance_count = var.environment == "production" ? 10 : 2
    }

    containers {
      image = var.worker_image
      ports {
        container_port = 8080
      }
      env {
        name  = "AEVO_ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "AEVO_CORE_API_ORIGIN"
        value = var.worker_core_api_origin
      }
      env {
        name  = "AEVO_PROBE_TARGETS"
        value = var.worker_probe_targets
      }
      dynamic "env" {
        for_each = var.worker_secret_ids
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }
  }
}

output "api_uri" {
  value = google_cloud_run_v2_service.core_api.uri
}

output "worker_uri" {
  value = google_cloud_run_v2_service.worker.uri
}

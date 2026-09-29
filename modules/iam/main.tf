variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  service_accounts = {
    core_api = "aevo-core-api-${var.environment}"
    worker   = "aevo-worker-${var.environment}"
    migrate  = "aevo-migrate-${var.environment}"
  }
}

resource "google_service_account" "runtime" {
  for_each     = local.service_accounts
  project      = var.project_id
  account_id   = each.value
  display_name = "Aevo ${each.key} runtime (${var.environment})"
}

output "service_account_emails" {
  value = { for key, account in google_service_account.runtime : key => account.email }
}

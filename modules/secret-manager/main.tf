variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "secret_names" {
  type = set(string)
}

variable "runtime_service_account_emails" {
  type = set(string)
}

resource "google_secret_manager_secret" "runtime" {
  for_each  = var.secret_names
  project   = var.project_id
  secret_id = "aevo/${var.environment}/${each.value}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "runtime_access" {
  for_each = {
    for pair in setproduct(var.secret_names, var.runtime_service_account_emails) :
    "${pair[0]}:${pair[1]}" => pair
  }
  project   = var.project_id
  secret_id = google_secret_manager_secret.runtime[each.value[0]].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value[1]}"
}

output "secret_ids" {
  value = { for key, secret in google_secret_manager_secret.runtime : key => secret.secret_id }
}

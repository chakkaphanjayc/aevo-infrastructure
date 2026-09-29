variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  type        = string
  default     = null
  description = "Optional operator email. Leave unset until a real destination is approved."
  nullable    = true
}

resource "google_monitoring_notification_channel" "operator_email" {
  count        = var.alert_email == null ? 0 : 1
  project      = var.project_id
  display_name = "Aevo ${var.environment} operator channel"
  type         = "email"
  enabled      = true
  labels       = { email_address = var.alert_email }
}

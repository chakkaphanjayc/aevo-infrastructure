variable "project_id" {
  type = string
}

variable "services" {
  type = set(string)
}

resource "google_project_service" "enabled" {
  for_each           = var.services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

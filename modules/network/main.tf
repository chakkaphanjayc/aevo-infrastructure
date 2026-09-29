variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

resource "google_compute_network" "runtime" {
  name                    = "aevo-${var.environment}-runtime"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "runtime" {
  name                     = "aevo-${var.environment}-runtime-${var.region}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.runtime.id
  ip_cidr_range            = "10.40.0.0/20"
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_services" {
  name          = "aevo-${var.environment}-private-services"
  project       = var.project_id
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = "10.50.0.0"
  prefix_length = 16
  network       = google_compute_network.runtime.id
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.runtime.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

resource "google_vpc_access_connector" "serverless" {
  name          = "aevo-${var.environment}-serverless"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.runtime.name
  ip_cidr_range = "10.60.0.0/28"
  min_instances = 2
  max_instances = var.environment == "production" ? 10 : 3
}

output "network_self_link" {
  value = google_compute_network.runtime.self_link
}

output "vpc_connector_id" {
  value = google_vpc_access_connector.serverless.id
}

output "private_services_connection_id" {
  value = google_service_networking_connection.private_services.id
}

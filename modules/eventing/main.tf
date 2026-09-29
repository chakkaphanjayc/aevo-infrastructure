variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

resource "google_pubsub_topic" "domain_events" {
  name    = "aevo-${var.environment}-domain-events"
  project = var.project_id
}

resource "google_pubsub_topic" "domain_events_dead_letter" {
  name    = "aevo-${var.environment}-domain-events-dead-letter"
  project = var.project_id
}

resource "google_pubsub_subscription" "worker" {
  name    = "aevo-${var.environment}-worker"
  project = var.project_id
  topic   = google_pubsub_topic.domain_events.id

  ack_deadline_seconds = 30

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.domain_events_dead_letter.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

resource "google_cloud_tasks_queue" "commands" {
  name     = "aevo-${var.environment}-commands"
  project  = var.project_id
  location = var.region

  retry_config {
    max_attempts       = 10
    max_retry_duration = "3600s"
    max_backoff        = "600s"
  }
}

output "domain_events_topic" {
  value = google_pubsub_topic.domain_events.name
}

output "commands_queue" {
  value = google_cloud_tasks_queue.commands.name
}

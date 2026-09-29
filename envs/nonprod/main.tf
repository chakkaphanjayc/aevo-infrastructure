terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "services" {
  source     = "../../modules/project"
  project_id = var.project_id
  services   = var.enabled_services
}

module "iam" {
  source      = "../../modules/iam"
  project_id  = var.project_id
  environment = var.environment
}

module "network" {
  source      = "../../modules/network"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  depends_on  = [module.services]
}

module "database" {
  source              = "../../modules/cloud-sql"
  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  tier                = var.database_tier
  private_network     = module.network.network_self_link
  deletion_protection = false
  depends_on          = [module.network]
}

module "secrets" {
  source                         = "../../modules/secret-manager"
  project_id                     = var.project_id
  environment                    = var.environment
  secret_names                   = var.secret_names
  runtime_service_account_emails = toset(values(module.iam.service_account_emails))
}

module "runtime" {
  source                 = "../../modules/cloud-run"
  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  api_image              = var.api_image
  worker_image           = var.worker_image
  api_service_account    = module.iam.service_account_emails["core_api"]
  worker_service_account = module.iam.service_account_emails["worker"]
  vpc_connector_id       = module.network.vpc_connector_id
  worker_pubsub_topic    = module.eventing.domain_events_topic
  worker_task_queue      = module.eventing.commands_queue
  worker_core_api_origin = var.worker_core_api_origin
  worker_probe_targets   = var.worker_probe_targets
  accounts_api_origin    = var.accounts_api_origin
  api_secret_ids = {
    AEVO_DATABASE_URL            = module.secrets.secret_ids["core-api-database-url"]
    AEVO_SESSION_SECRET          = module.secrets.secret_ids["core-api-session-secret"]
    AEVO_CORE_API_SERVICE_SECRET = module.secrets.secret_ids["core-api-service-secret"]
    AEVO_ACCOUNTS_SERVICE_SECRET = module.secrets.secret_ids["accounts-service-secret"]
    AEVO_ORIGIN_SIGNING_SECRET   = module.secrets.secret_ids["origin-signing-secret"]
    AEVO_CONNECTION_PROBE_TOKEN  = module.secrets.secret_ids["connection-probe-token"]
    AEVO_FEED_CURSOR_SECRET      = module.secrets.secret_ids["feed-cursor-secret"]
    AEVO_FEED_EVENT_WORKER_TOKEN = module.secrets.secret_ids["feed-event-worker-token"]
  }
  worker_secret_ids = {
    AEVO_DATABASE_URL            = module.secrets.secret_ids["core-api-database-url"]
    AEVO_CONNECTION_PROBE_TOKEN  = module.secrets.secret_ids["connection-probe-token"]
    AEVO_WORKER_SHARED_SECRET    = module.secrets.secret_ids["worker-shared-secret"]
    AEVO_FEED_EVENT_WORKER_TOKEN = module.secrets.secret_ids["feed-event-worker-token"]
  }
}

module "eventing" {
  source      = "../../modules/eventing"
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
}

module "observability" {
  source      = "../../modules/observability"
  project_id  = var.project_id
  environment = var.environment
}

variable "project_id" {
  type        = string
  description = "Dedicated bootstrap project ID."
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique Terraform state bucket name."
}

variable "region" {
  type        = string
  description = "Bootstrap resource region."
  default     = "asia-southeast1"
}

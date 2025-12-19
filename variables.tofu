# Input Variables
# https://opentofu.org/docs/language/values/variables

# This is only needed during bootstrapping.
# variable "billing_project" {
#   description = "The quota project to send in `user_project_override`, used for all requests sent from the provider. If set on a resource that supports sending the resource project, this value will supersede the resource project. This field is ignored if `user_project_override` is set to false or unset"
#   type        = string
# }

variable "datadog_api_key" {
  description = "Datadog API key"
  sensitive   = true
  type        = string
}

variable "datadog_app_key" {
  description = "Datadog APP key"
  sensitive   = true
  type        = string
}

variable "datadog_enable" {
  default     = false
  description = "Enable Datadog integration"
  type        = bool
}

variable "dns_records_admins" {
  default     = []
  description = "The set of service accounts that can administer DNS records in the networking project"
  type        = set(string)
}

variable "google_customer_id" {
  default     = "C01hd34v8"
  description = "The unique customer ID assigned to you when you signed up for Google Workspace or Cloud Identity. You can look up this ID in your Admin console"
  type        = string
}

variable "iam_admins" {
  default     = []
  description = "The set of service accounts that can administer IAM in the networking project"
  type        = set(string)
}

variable "kubernetes_project_monthly_budget_amount" {
  default     = 5
  description = "The monthly budget amount in USD to set for Kubernetes projects"
  type        = number
}

variable "private_record_sets" {
  default     = []
  description = "Private DNS record sets"
  type = list(object({
    name    = string
    rrdatas = list(string)
    ttl     = number
    type    = string
  }))
}

variable "project_billing_account" {
  default     = "01C550-A2C86B-B8F16B"
  description = "The alphanumeric ID of the billing account this project belongs to"
  type        = string
}

variable "project_monthly_budget_amount" {
  default     = 5
  description = "The monthly budget amount in USD to set for the project"
  type        = number
}

variable "public_record_sets" {
  default     = []
  description = "Public DNS record sets"
  type = list(object({
    name    = string
    rrdatas = list(string)
    ttl     = number
    type    = string
  }))
}

# These three state_* variables are required for early variable evaluation for backend and provider configuration.
# They are defined in the GitHub Actions called workflows and should NOT be set in the OpenTofu configuration.

variable "state_bucket" {
  description = "The name of the GCS bucket to store state files"
  type        = string
}

variable "state_kms_encryption_key" {
  description = "The KMS encryption key for state and plan files"
  type        = string
}

variable "state_prefix" {
  description = "The prefix for state files in the GCS bucket"
  type        = string
}

variable "vpc_service_projects" {
  default     = {}
  description = "The map of Kubernetes service project IDs and numbers (The number should only be added if the project is a Kubernetes service project)"
  type = map(object({
    number = optional(number)
  }))
}

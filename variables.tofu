# Input Variables
# https://opentofu.org/docs/language/values/variables

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

variable "google_customer_id" {
  description = "The unique customer ID assigned to you when you signed up for Google Workspace or Cloud Identity. You can look up this ID in your Admin console"
  type        = string
  default     = "C01hd34v8"
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

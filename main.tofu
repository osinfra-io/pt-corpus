# Datadog Google Cloud Platform Integration Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-datadog-google-integration

module "datadog" {
  source = "github.com/osinfra-io/opentofu-datadog-google-integration?ref=e0f6e37034c7e8e3b69edaa100eb48d9d3f7f9e5" # v0.3.6
  count  = var.datadog_enable ? 1 : 0

  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.helpers.labels
  project                            = module.project.id
}

# Google Project Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-project

module "project" {
  source = "github.com/osinfra-io/opentofu-google-project?ref=655916e58848e16af406e4968b25bb77fb0f1119" # v0.4.5

  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = var.project_cis_2_2_logging_sink_project_id
  description                     = "corpus"
  folder_id                       = local.environment_folder_id
  labels                          = module.helpers.labels
  monthly_budget_amount           = var.project_monthly_budget_amount
  prefix                          = local.team_name

  services = [
    "billingbudgets.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

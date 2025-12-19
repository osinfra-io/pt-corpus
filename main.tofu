# Datadog Google Cloud Platform Integration Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-datadog-google-integration

module "datadog" {
  count  = var.datadog_enable ? 1 : 0
  source = "github.com/osinfra-io/opentofu-datadog-google-integration?ref=e0f6e37034c7e8e3b69edaa100eb48d9d3f7f9e5" # v0.3.6

  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.helpers.labels
  project                            = module.project.id
}

# Google Project Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-project

module "project" {
  source = "github.com/osinfra-io/opentofu-google-project?ref=e0c6729c1760e2c580dffac13cbd834776c2aa3b" # v0.4.7

  billing_account       = var.project_billing_account
  deletion_policy       = "DELETE"
  description           = module.helpers.project_naming.description
  folder_id             = module.helpers.environment_folder_id
  labels                = module.helpers.labels
  monthly_budget_amount = var.project_monthly_budget_amount
  prefix                = module.helpers.project_naming.prefix

  services = [
    "billingbudgets.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "securitycenter.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sts.googleapis.com"
  ]
}

# Google Kubernetes Project Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-project
# Create Kubernetes projects for teams with google_kubernetes_engine_clusters

module "kubernetes_projects" {
  for_each = local.teams_with_gke_clusters
  source   = "github.com/osinfra-io/opentofu-google-project?ref=e0c6729c1760e2c580dffac13cbd834776c2aa3b" # v0.4.7

  billing_account = var.project_billing_account
  deletion_policy = "DELETE"
  description     = "k8s"

  folder_id = module.helpers.teams[each.key].environments[local.environment_key]

  labels = merge(
    module.helpers.labels,
    {
      team = each.key
    }
  )

  monthly_budget_amount = var.kubernetes_project_monthly_budget_amount
  prefix                = each.key

  services = concat(
    [
      "billingbudgets.googleapis.com",
      "cloudasset.googleapis.com",
      "cloudbilling.googleapis.com",
      "cloudkms.googleapis.com",
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "monitoring.googleapis.com",
      "multiclusterservicediscovery.googleapis.com",
      "securitycenter.googleapis.com",
      "serviceusage.googleapis.com",
      "trafficdirector.googleapis.com"
    ],
    each.value.has_gke_hub_host ? [
      "gkehub.googleapis.com",
      "multiclusteringress.googleapis.com"
    ] : []
  )
}

# Datadog Google Cloud Platform Integration for Kubernetes Projects
# https://github.com/osinfra-io/opentofu-datadog-google-integration

module "kubernetes_datadog" {
  for_each = var.datadog_enable ? local.teams_with_gke_clusters : {}
  source   = "github.com/osinfra-io/opentofu-datadog-google-integration?ref=e0f6e37034c7e8e3b69edaa100eb48d9d3f7f9e5" # v0.3.6

  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.helpers.labels
  project                            = module.kubernetes_projects[each.key].id
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-cloud-dns

module "private_dns" {
  source = "github.com/osinfra-io/opentofu-google-network//dns?ref=v0.2.3"

  dns_name = module.helpers.env == "prod" ? "priv.gcp.osinfra.io." : "${module.helpers.env}.gcp.priv.osinfra.io."
  labels   = module.helpers.labels
  name     = module.helpers.env == "prod" ? "priv-gcp-osinfra-io" : "${module.helpers.env}-gcp-priv-osinfra-io"

  private_visibility_config_networks = [
    module.vpc.self_link
  ]

  project    = module.project.id
  visibility = "private"
}

module "public_dns" {
  for_each = local.teams_with_dns_zones
  source   = "github.com/osinfra-io/opentofu-google-network//dns?ref=v0.2.3"

  dns_name = each.value.dns_name

  labels = merge(
    module.helpers.labels,
    {
      team = each.key
    }
  )

  name       = each.value.name
  project    = module.project.id
  visibility = "public"
}

# Google Cloud NAT Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-cloud-nat

# Note: Regional resources like Cloud NAT and subnets would need to be deployed per region
# This implementation focuses on the main pt-corpus project infrastructure
# Regional deployments would be handled separately per region as needed

# Google Subnet Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-subnet

# Note: Subnet creation is handled regionally. The subnet configuration from pt-logos
# provides the blueprint, but actual deployment would be done in region-specific workspaces
# or with regional module invocations that include proper helpers configuration

# Google Storage Bucket Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-storage-bucket

module "state_storage_bucket" {
  for_each = local.service_accounts
  source   = "github.com/osinfra-io/opentofu-google-storage-bucket?ref=642c3eb45623e0e619dcc3c80c98ef804da7c153" # v0.2.1

  labels   = module.helpers.labels
  location = "us"
  name     = "${each.key}-state-${module.helpers.env}"
  project  = module.project.id
}

# Google VPC Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-vpc

module "vpc" {
  source = "github.com/osinfra-io/opentofu-google-network?ref=v0.2.3"

  name       = "standard-shared"
  project    = module.project.id
  shared_vpc = true
}

# Google Identity Group Membership
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/cloud_identity_group_membership

# Billing users group membership - group created centrally in pt-logos, membership managed per team
resource "google_cloud_identity_group_membership" "github_actions" {
  for_each = local.service_accounts

  depends_on = [
    module.project
  ]

  create_ignore_already_exists = true
  group                        = local.billing_users_group_name

  preferred_member_key {
    id = google_service_account.github_actions[each.key].email
  }

  roles { name = "MEMBER" }

  dynamic "roles" {
    for_each = each.key == "pt-corpus" ? [1] : []

    content {
      name = "MANAGER"
    }
  }
}

# Browser group membership - allows service accounts to list/discover resources in environment folders
# Service accounts for teams other than pt-corpus need browser permissions
resource "google_cloud_identity_group_membership" "browsers" {
  for_each = { for key, sa in local.service_accounts : key => sa if key != "pt-corpus" }

  depends_on = [
    module.project
  ]

  create_ignore_already_exists = true
  group                        = local.browser_group_name

  preferred_member_key {
    id = google_service_account.github_actions[each.key].email
  }

  roles { name = "MEMBER" }
}

# Compute Global Address Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_global_address

resource "google_compute_global_address" "service_network_peering_range" {
  address       = "172.16.0.0"
  address_type  = "INTERNAL"
  labels        = module.helpers.labels
  name          = "service-network-peering-range"
  network       = module.vpc[0].self_link
  prefix_length = 16
  project       = module.project.id
  purpose       = "VPC_PEERING"
}

# Compute Shared VPC Service Project Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_shared_vpc_service_project

resource "google_compute_shared_vpc_service_project" "this" {
  for_each = local.vpc_service_projects

  host_project    = module.project.id
  service_project = each.key
}

# Compute Subnetwork IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_subnetwork_iam

# Note: Subnet IAM bindings would be configured in regional deployments
# once subnets are created in specific region workspaces

# DNS Record Set Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/dns_record_set

resource "google_dns_record_set" "private" {
  for_each = { for record in var.private_record_sets : join("-", [record.name, lower(record.type)]) => record }

  managed_zone = module.private_dns.name
  name         = "${each.value.name}.${module.private_dns[0].dns_name}"
  project      = module.project.id
  rrdatas      = each.value.rrdatas
  ttl          = each.value.ttl
  type         = each.value.type
}

resource "google_dns_record_set" "public" {
  for_each = length(module.public_dns) > 0 ? { for record in var.public_record_sets : join("-", [record.name, lower(record.type)]) => record } : {}

  managed_zone = values(module.public_dns)[0].name
  name         = "${each.value.name}.${values(module.public_dns)[0].dns_name}"
  project      = module.project.id
  rrdatas      = each.value.rrdatas
  ttl          = each.value.ttl
  type         = each.value.type
}

# Project IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_project_iam_member

resource "google_project_iam_member" "container_engine_firewall_management" {
  for_each = local.vpc_service_projects_kubernetes

  member  = "serviceAccount:service-${each.value.number}@container-engine-robot.iam.gserviceaccount.com"
  project = module.project.id
  role    = "organizations/163313809793/roles/kubernetes.hostFirewallManagement"
}

resource "google_project_iam_member" "container_engine_service_agent_user" {
  for_each = local.vpc_service_projects_kubernetes

  member  = "serviceAccount:service-${each.value.number}@container-engine-robot.iam.gserviceaccount.com"
  project = module.project.id
  role    = "roles/container.hostServiceAgentUser"
}

resource "google_project_iam_member" "dns_records_admins" {
  for_each = var.dns_records_admins

  member  = "serviceAccount:${each.key}"
  project = module.project.id
  role    = "organizations/163313809793/roles/dns.recordsAdmin"
}

resource "google_project_iam_member" "iam_admins" {
  for_each = var.iam_admins

  member  = "serviceAccount:${each.key}"
  project = module.project.id
  role    = "roles/resourcemanager.projectIamAdmin"
}

resource "google_project_iam_member" "kubernetes_project_owners" {
  for_each = local.teams_with_gke_clusters

  member  = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  project = module.kubernetes_projects[each.key].id
  role    = "roles/owner"
}

# Service Networking Connection Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/service_networking_connection

resource "google_service_networking_connection" "this" {
  network                 = module.vpc.self_link
  reserved_peering_ranges = [google_compute_global_address.service_network_peering_range.name]
  service                 = "servicenetworking.googleapis.com"
}

# Google KMS Crypto Key Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_crypto_key

resource "google_kms_crypto_key" "state_encryption" {
  # We can't use the lifecycle block to prevent destroy on this resource for testing purposes.

  # CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed CryptoKey will
  # remove it from state and delete all CryptoKeyVersions, rendering the key unusable, but will not delete
  # the resource from the project. When OpenTofu destroys these keys, any data previously encrypted with
  # these keys will be irrecoverable. For this reason, it is strongly recommended that you add lifecycle
  # hooks to the resource to prevent accidental destruction.

  # lifecycle {
  #   prevent_destroy = true
  # }

  key_ring        = google_kms_key_ring.state_encryption.id
  labels          = module.helpers.labels
  name            = "default"
  rotation_period = "7776000s"
}


# Google KMS Crypto Key IAM Member
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member

# BUG: https://github.com/hashicorp/terraform-provider-google/issues/7611
resource "google_kms_crypto_key_iam_member" "cloud_storage_service_account" {
  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = "serviceAccount:service-${module.project.number}@gs-project-accounts.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "github_actions" {
  for_each = local.service_accounts

  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Google KMS Key Ring Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_key_ring

resource "google_kms_key_ring" "state_encryption" {
  # We can't use the lifecycle block to prevent destroy on this resource for testing purposes.

  # KeyRings cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed KeyRing will remove it from
  # state but will not delete the resource from the project.

  # lifecycle {
  #   prevent_destroy = true
  # }

  location = "us"
  name     = "state-encryption"
  project  = module.project.id
}

# Google Service Account Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_service_account

resource "google_service_account" "github_actions" {
  for_each = local.service_accounts

  account_id   = "${each.key}-github"
  display_name = "Service account for GitHub Actions"
  project      = module.project.id
}

# Google Service Account IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member

resource "google_service_account_iam_member" "github_actions" {
  for_each = local.github_repositories

  member             = "principalSet://iam.googleapis.com/projects/${module.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.this["github-actions"].workload_identity_pool_id}/attribute.repository/osinfra-io/${each.value.repository}"
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.github_actions[each.value.name].id
}

# Google Storage Bucket IAM Member
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/storage_bucket_iam#google_storage_bucket_iam_member

resource "google_storage_bucket_iam_member" "github_actions" {
  for_each = local.service_accounts

  bucket = module.state_storage_bucket[each.key].name
  member = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  role   = "roles/storage.objectAdmin"
}

# To avoid subject collisions, we are using a single provider per workload identity pool.
# https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation#avoid-subject-collisions

# IAM Workload Identity Pool Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/iam_workload_identity_pool

resource "google_iam_workload_identity_pool" "this" {
  for_each = local.workload_identity

  description               = "Workload Identity Pool for ${each.value.display_name}"
  disabled                  = lookup(each.value, "disabled", false)
  display_name              = each.value.display_name
  project                   = module.project.id
  workload_identity_pool_id = each.key
}

# IAM Workload Identity Pool Provider Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider

resource "google_iam_workload_identity_pool_provider" "this" {
  for_each = local.workload_identity

  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  description                        = "Workload Identity Pool Provider for ${each.value.display_name}"
  disabled                           = lookup(each.value, "disabled", false)
  display_name                       = "${each.value.display_name} OIDC"
  project                            = module.project.id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "${each.key}-oidc"

  oidc {
    allowed_audiences = lookup(each.value, "allowed_audiences", [])
    issuer_uri        = each.value.issuer_uri
  }
}

# Datadog Google Cloud Platform Integration Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-datadog-google-integration

module "datadog_google_integration" {
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=96d35be7846e15d3ea60c27dab0a6a72e259d3ae" # v0.4.6

  lifecycle {
    enabled = var.datadog_enable
  }

  api_key                            = var.datadog_api_key
  enable_cloud_cost_management       = local.enable_cloud_cost_management
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.core_helpers.labels
  project                            = module.google_project.id
}

module "datadog_google_integration_datadog_projects" {
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=96d35be7846e15d3ea60c27dab0a6a72e259d3ae" # v0.4.6

  for_each                           = local.datadog_google_project_for_each
  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = local.team_labels[each.value.team_key]
  project                            = module.google_project_teams[each.key].id
}

module "datadog_google_integration_platform_managed_projects" {
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=96d35be7846e15d3ea60c27dab0a6a72e259d3ae" # v0.4.6

  for_each                           = local.datadog_platform_managed_for_each
  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.core_helpers.labels
  project                            = module.google_project_platform_managed[each.key].id
}

# Google VPC Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_vpc" {
  source = "github.com/osinfra-io/pt-arche-google-network?ref=ba20bee164e911915abc3b0f1145993f29199cb2" # v0.3.6

  name       = "standard-shared"
  project    = module.google_project.id
  shared_vpc = true
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_osinfra_io_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=ba20bee164e911915abc3b0f1145993f29199cb2" # v0.3.6

  dns_name   = local.osinfra_io_dns_zone_name
  labels     = module.core_helpers.labels
  name       = local.osinfra_io_dns_name
  project    = module.google_project.id
  visibility = "public"
}

module "google_network_private_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=ba20bee164e911915abc3b0f1145993f29199cb2" # v0.3.6

  dns_name = local.private_dns_zone_name
  labels   = module.core_helpers.labels
  name     = local.private_dns_name

  private_visibility_config_networks = [
    module.google_network_vpc.self_link
  ]

  project    = module.google_project.id
  visibility = "private"
}

module "google_network_team_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=ba20bee164e911915abc3b0f1145993f29199cb2" # v0.3.6

  for_each   = local.teams_with_dns_zones
  dns_name   = each.value.dns_name
  labels     = local.team_labels[each.key]
  name       = each.value.name
  project    = module.google_project.id
  visibility = "public"
}

# Google Project Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-project

module "google_project" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=dc72cc73addab260dc8cb3df719aa69b66b8b774" # v0.7.1

  billing_account       = var.project_billing_account
  deletion_policy       = "DELETE"
  folder_id             = module.core_helpers.environment_folder_id
  labels                = module.core_helpers.labels
  monthly_budget_amount = var.project_monthly_budget_amount
  prefix                = module.core_helpers.project_naming.team_key

  services = [
    "artifactregistry.googleapis.com",
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

module "google_project_platform_managed" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=dc72cc73addab260dc8cb3df719aa69b66b8b774" # v0.7.1

  for_each                        = local.teams_with_platform_managed_projects
  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = module.google_project.id
  deletion_policy                 = "DELETE"
  folder_id                       = module.core_helpers.teams[each.key].environments[local.environment_key]
  labels                          = merge(local.team_labels[each.key], { "project-type" = "platform-managed" })
  monthly_budget_amount           = var.platform_managed_project_monthly_budget_amount
  prefix                          = each.key
  services                        = local.platform_managed_project_services[each.key]
}

module "google_project_teams" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=dc72cc73addab260dc8cb3df719aa69b66b8b774" # v0.7.1

  for_each                        = local.google_projects
  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = module.google_project.id
  deletion_policy                 = "DELETE"
  folder_id                       = module.core_helpers.teams[each.key].environments[local.environment_key]
  labels                          = local.team_labels[each.key]
  monthly_budget_amount           = var.project_monthly_budget_amount
  prefix                          = each.key
  services                        = local.team_project_services[each.key]
}

# Google Storage Bucket Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-storage-bucket

module "google_storage_bucket" {
  source = "github.com/osinfra-io/pt-arche-google-storage-bucket?ref=b518fbdf3d480f827e2f360d97ce4d0600a3ff3b" # v0.3.4

  for_each = local.opentofu_state_management
  labels   = module.core_helpers.labels
  location = "us"
  name     = "${each.key}-state-${module.core_helpers.env}"
  project  = module.google_project.id
}

# Google Artifact Registry Repository
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/artifact_registry_repository

resource "google_artifact_registry_repository" "docker_remote" {
  lifecycle {
    enabled = length(local.teams_with_artifact_registries) > 0
  }

  description = "Registry for multi-region - US Docker Hub"
  format      = "DOCKER"
  labels      = module.core_helpers.labels
  location    = "us"
  mode        = "REMOTE_REPOSITORY"
  project     = module.google_project.id

  remote_repository_config {
    description = "docker hub"
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }

  repository_id = "docker-remote"
}

resource "google_artifact_registry_repository" "docker_standards" {
  for_each = local.teams_with_artifact_registries

  description   = "Registry for multi-region - US Standard : ${each.key}"
  format        = "DOCKER"
  labels        = module.core_helpers.labels
  location      = "us"
  project       = module.google_project.id
  repository_id = "${each.key}-standard"
}

resource "google_artifact_registry_repository" "docker_virtuals" {
  for_each = local.teams_with_artifact_registries

  description   = "Registry for multi-region - US Virtual : ${each.key}"
  format        = "DOCKER"
  labels        = module.core_helpers.labels
  location      = "us"
  mode          = "VIRTUAL_REPOSITORY"
  project       = module.google_project.id
  repository_id = "${each.key}-virtual"

  virtual_repository_config {
    upstream_policies {
      id         = each.key
      priority   = 20
      repository = google_artifact_registry_repository.docker_standards[each.key].id
    }

    upstream_policies {
      id         = "docker"
      priority   = 10
      repository = google_artifact_registry_repository.docker_remote.id
    }
  }
}

# Google Artifact Registry IAM Binding
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam

resource "google_artifact_registry_repository_iam_binding" "docker_standard_writers" {
  for_each = local.teams_with_artifact_registries

  location   = "us"
  members    = each.value.registry_writers
  project    = module.google_project.id
  repository = google_artifact_registry_repository.docker_standards[each.key].id
  role       = "roles/artifactregistry.writer"
}

resource "google_artifact_registry_repository_iam_binding" "docker_virtual_readers" {
  for_each = local.teams_with_artifact_registries

  location   = "us"
  members    = each.value.registry_readers
  project    = module.google_project.id
  repository = google_artifact_registry_repository.docker_virtuals[each.key].id
  role       = "roles/artifactregistry.reader"
}

# Google Identity Group Membership
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/cloud_identity_group_membership

# Browser group membership
# Allows service accounts to list/discover resources in environment folders.
# Service accounts for teams other than pt-corpus need browser permissions.
resource "google_cloud_identity_group_membership" "browsers" {
  depends_on = [
    module.google_project
  ]

  for_each = local.non_corpus_service_accounts

  create_ignore_already_exists = true
  group                        = local.browser_group_name

  preferred_member_key {
    id = google_service_account.github_actions[each.key].email
  }

  roles { name = "MEMBER" }
}

# Billing users group membership
# Group created centrally in pt-logos, membership managed per team.
resource "google_cloud_identity_group_membership" "github_actions" {
  depends_on = [
    module.google_project
  ]

  for_each = local.service_accounts

  create_ignore_already_exists = true
  group                        = local.billing_users_group_name

  preferred_member_key {
    id = google_service_account.github_actions[each.key].email
  }

  roles { name = "MEMBER" }

  dynamic "roles" {
    for_each = local.billing_users_manager_for_each[each.key]

    content {
      name = "MANAGER"
    }
  }
}

# Logos state readers group membership
# Allows service accounts to read Logos OpenTofu state so all teams can use
# pt-arche-core-helpers root module for team data.
resource "google_cloud_identity_group_membership" "logos_state_readers" {
  depends_on = [
    module.google_project
  ]

  for_each = local.non_corpus_service_accounts

  create_ignore_already_exists = true
  group                        = local.logos_state_readers_group_name

  preferred_member_key {
    id = google_service_account.github_actions[each.key].email
  }

  roles { name = "MEMBER" }
}

# Registry writers group membership
# Adds each team's GitHub Actions SA as a member of the registry-writers group
# so release workflows can push images to Artifact Registry.
resource "google_cloud_identity_group_membership" "registry_writers" {
  for_each = local.teams_with_artifact_registries

  create_ignore_already_exists = true
  group                        = module.core_helpers.teams[each.key].identity_groups["registry-writers"].name

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
  labels        = module.core_helpers.labels
  name          = "service-network-peering-range"
  network       = module.google_network_vpc.self_link
  prefix_length = 16
  project       = module.google_project.id
  purpose       = "VPC_PEERING"
}

# Compute Shared VPC Service Project Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_shared_vpc_service_project

resource "google_compute_shared_vpc_service_project" "this" {
  for_each = local.vpc_service_projects

  host_project    = module.google_project.id
  service_project = each.value.id
}

# DNS Record Set Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/dns_record_set

resource "google_dns_record_set" "osinfra_io_ns_delegations" {
  for_each = { for delegation in var.osinfra_io_ns_delegations : delegation.name => delegation }

  managed_zone = each.value.managed_zone
  name         = "${each.value.name}."
  project      = module.google_project.id
  rrdatas      = each.value.rrdatas
  ttl          = each.value.ttl
  type         = "NS"
}

resource "google_dns_record_set" "team_ns_delegations" {
  for_each = module.google_network_team_dns

  managed_zone = module.google_network_osinfra_io_dns.name
  name         = each.value.dns_name
  project      = module.google_project.id
  rrdatas      = each.value.name_servers
  ttl          = 300
  type         = "NS"
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
  project                   = module.google_project.id
  workload_identity_pool_id = each.key
}

# IAM Workload Identity Pool Provider Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider

resource "google_iam_workload_identity_pool_provider" "this" {
  for_each = local.workload_identity

  attribute_condition = each.value.attribute_condition
  attribute_mapping   = each.value.attribute_mapping
  description         = "Workload Identity Pool Provider for ${each.value.display_name}"
  disabled            = lookup(each.value, "disabled", false)
  display_name        = "${each.value.display_name} OIDC"

  oidc {
    allowed_audiences = lookup(each.value, "allowed_audiences", [])
    issuer_uri        = each.value.issuer_uri
  }

  project                            = module.google_project.id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "${each.key}-oidc"
}

# Google KMS Crypto Key Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_crypto_key

resource "google_kms_crypto_key" "state_encryption" {
  # CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed CryptoKey will
  # remove it from state and delete all CryptoKeyVersions, rendering the key unusable, but will not delete
  # the resource from the project. When OpenTofu destroys these keys, any data previously encrypted with
  # these keys will be irrecoverable. For this reason, it is strongly recommended that you add lifecycle
  # hooks to the resource to prevent accidental destruction.

  lifecycle {
    prevent_destroy = true
  }

  key_ring        = google_kms_key_ring.state_encryption.id
  labels          = module.core_helpers.labels
  name            = "default"
  rotation_period = "7776000s"
}

# Google KMS Crypto Key IAM Member
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member

# BUG: https://github.com/hashicorp/terraform-provider-google/issues/7611
resource "google_kms_crypto_key_iam_member" "cloud_storage_service_account" {
  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = "serviceAccount:service-${module.google_project.number}@gs-project-accounts.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "github_actions" {
  for_each = local.opentofu_state_management

  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "logos_state_readers" {
  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = "group:${module.core_helpers.teams["pt-logos"].identity_groups["state-readers"].email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Google KMS Key Ring Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_key_ring

resource "google_kms_key_ring" "state_encryption" {
  # KeyRings cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed KeyRing will remove it from
  # state but will not delete the resource from the project.

  lifecycle {
    prevent_destroy = true
  }

  location = "us"
  name     = "state-encryption"
  project  = module.google_project.id
}

# Project IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_project_iam_member

resource "google_project_iam_member" "container_engine_firewall_management" {
  for_each = local.vpc_service_projects_platform_managed

  member  = "serviceAccount:service-${each.value.number}@container-engine-robot.iam.gserviceaccount.com"
  project = module.google_project.id
  role    = "organizations/163313809793/roles/kubernetes.hostFirewallManagement"
}

resource "google_project_iam_member" "container_engine_service_agent_user" {
  for_each = local.vpc_service_projects_platform_managed

  member  = "serviceAccount:service-${each.value.number}@container-engine-robot.iam.gserviceaccount.com"
  project = module.google_project.id
  role    = "roles/container.hostServiceAgentUser"
}

# DNS Records Admin for Teams with GKE Clusters
# Teams with Kubernetes clusters need to manage DNS records for their Istio gateways.

resource "google_project_iam_member" "dns_records_admins_gke_teams" {
  for_each = local.gke_teams_with_service_accounts

  member  = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  project = module.google_project.id
  role    = "organizations/163313809793/roles/dns.recordsAdmin"
}

# Google Project Owners
# Grant team service accounts owner role on their google_projects.

resource "google_project_iam_member" "google_project_owners" {
  for_each = local.google_projects_with_service_accounts

  member  = "serviceAccount:${google_service_account.github_actions[each.value.team_key].email}"
  project = module.google_project_teams[each.key].id
  role    = "roles/owner"
}

# Platform-Managed Project Owners
# Grant team service accounts owner role on their platform-managed projects.

resource "google_project_iam_member" "platform_managed_project_owners" {
  for_each = local.gke_teams_with_service_accounts

  member  = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  project = module.google_project_platform_managed[each.key].id
  role    = "roles/owner"
}

# Platform-Managed Project Pneuma Owners
# Grant the pt-pneuma service account owner role on all other teams' platform-managed projects
# so pt-pneuma can provision and manage GKE clusters on behalf of all teams.

resource "google_project_iam_member" "platform_managed_project_pneuma_owners" {
  for_each = local.gke_teams_for_pneuma_access

  member  = "serviceAccount:${google_service_account.github_actions["pt-pneuma"].email}"
  project = module.google_project_platform_managed[each.key].id
  role    = "roles/owner"
}

resource "google_project_iam_member" "multi_cluster_service_agents" {
  for_each = local.teams_with_gke_hub_host

  member  = "serviceAccount:${google_project_service_identity.multi_cluster_service_agents[each.key].email}"
  project = module.google_project.id
  role    = "roles/multiclusterservicediscovery.serviceAgent"
}

# Google Project Service Identity Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_project_service_identity

resource "google_project_service_identity" "multi_cluster_service_agents" {
  depends_on = [module.google_project_platform_managed]
  for_each   = local.teams_with_gke_hub_host
  provider   = google-beta # Required for google_project_service_identity

  project = module.google_project_platform_managed[each.key].id
  service = "multiclusterservicediscovery.googleapis.com"
}

# Google Service Account Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_service_account

resource "google_service_account" "github_actions" {
  for_each = local.service_accounts

  account_id   = "${each.key}-github"
  display_name = "Service account for GitHub Actions"
  project      = module.google_project.id
}

# Google Service Account IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member

resource "google_service_account_iam_member" "github_actions" {
  for_each = local.github_repositories

  member             = "principalSet://iam.googleapis.com/projects/${module.google_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.this["github-actions"].workload_identity_pool_id}/attribute.repository/osinfra-io/${each.value.repository}"
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.github_actions[each.value.name].id
}

# Service Networking Connection Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/service_networking_connection

resource "google_service_networking_connection" "this" {
  network = module.google_network_vpc.self_link

  reserved_peering_ranges = [google_compute_global_address.service_network_peering_range.name]

  service = "servicenetworking.googleapis.com"
}

# Google Storage Bucket IAM Member
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/storage_bucket_iam#google_storage_bucket_iam_member

resource "google_storage_bucket_iam_member" "github_actions" {
  for_each = local.opentofu_state_management

  bucket = module.google_storage_bucket[each.key].name
  member = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  role   = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_member" "logos_state_readers" {
  bucket = module.google_storage_bucket["pt-logos"].name
  member = "group:${module.core_helpers.teams["pt-logos"].identity_groups["state-readers"].email}"
  role   = "roles/storage.objectViewer"
}

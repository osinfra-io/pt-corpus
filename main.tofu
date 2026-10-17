# Datadog Google Cloud Platform Integration Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-datadog-google-integration

module "datadog_google_integration" {
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=31b789703a19107de72429552d953d86099f499b" # v0.4.11

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
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=31b789703a19107de72429552d953d86099f499b" # v0.4.11

  for_each                           = local.datadog_team_projects
  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = local.team_labels[each.value.team_key]
  project                            = module.google_project_teams[each.key].id
}

module "datadog_google_integration_platform_managed_projects" {
  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=31b789703a19107de72429552d953d86099f499b" # v0.4.11

  for_each                           = local.datadog_platform_managed_projects
  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.core_helpers.labels
  project                            = module.google_project_platform_managed[each.key].id
}

# Google VPC Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_vpc" {
  source = "github.com/osinfra-io/pt-arche-google-network?ref=8672fee08f5f4affc839bf9b5fe7485476db10e1" # v0.3.12

  name       = "standard-shared"
  project    = module.google_project.id
  shared_vpc = true
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_osinfra_io_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=8672fee08f5f4affc839bf9b5fe7485476db10e1" # v0.3.12

  dns_name   = local.osinfra_io_dns_zone_name
  labels     = module.core_helpers.labels
  name       = local.osinfra_io_dns_name
  project    = module.google_project.id
  visibility = "public"
}

module "google_network_private_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=8672fee08f5f4affc839bf9b5fe7485476db10e1" # v0.3.12

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
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=8672fee08f5f4affc839bf9b5fe7485476db10e1" # v0.3.12

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
  source = "github.com/osinfra-io/pt-arche-google-project?ref=44619253d858e84c7706e21e6bd92c5410a7f71a" # v0.9.0

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
    "sqladmin.googleapis.com",
    "sts.googleapis.com"
  ]
}

module "google_project_platform_managed" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=44619253d858e84c7706e21e6bd92c5410a7f71a" # v0.9.0

  for_each                        = local.teams_with_platform_managed_projects
  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = module.google_project.id
  deletion_policy                 = "DELETE"
  folder_id                       = module.core_helpers.teams[each.key].environments[local.environment_key]
  labels                          = local.platform_managed_project_labels[each.key]
  monthly_budget_amount           = var.platform_managed_project_monthly_budget_amount
  prefix                          = each.key
  services                        = local.platform_managed_project_services[each.key]
}

module "google_project_teams" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=44619253d858e84c7706e21e6bd92c5410a7f71a" # v0.9.0

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
  source = "github.com/osinfra-io/pt-arche-google-storage-bucket?ref=8eb9bf7d7a42e9d31b3f2528fd88487c5fca9b79" # v0.3.8

  for_each = local.opentofu_state_management
  labels   = module.core_helpers.labels
  location = "us"
  name     = each.value.bucket_name
  project  = module.google_project.id
}

# Google Artifact Registry Repository
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/artifact_registry_repository

resource "google_artifact_registry_repository" "docker_remote" {
  lifecycle {
    enabled = local.enable_docker_remote_registry
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

  description   = each.value.standard_description
  format        = "DOCKER"
  labels        = module.core_helpers.labels
  location      = "us"
  project       = module.google_project.id
  repository_id = each.value.standard_repository_id
}

resource "google_artifact_registry_repository" "docker_virtuals" {
  for_each = local.teams_with_artifact_registries

  description   = each.value.virtual_description
  format        = "DOCKER"
  labels        = module.core_helpers.labels
  location      = "us"
  mode          = "VIRTUAL_REPOSITORY"
  project       = module.google_project.id
  repository_id = each.value.virtual_repository_id

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
  group                        = local.browsers_group_name

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
  group                        = module.core_helpers.teams["pt-logos"].billing_users_group.name

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
  group                        = module.core_helpers.teams["pt-logos"].identity_groups["state-readers"].name

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
  for_each = local.osinfra_io_ns_delegations

  managed_zone = each.value.managed_zone
  name         = each.value.name
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
  description               = "Workload Identity Pool for GitHub Actions"
  display_name              = "GitHub Actions"
  project                   = module.google_project.id
  workload_identity_pool_id = "github-actions"
}

# IAM Workload Identity Pool Provider Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider

resource "google_iam_workload_identity_pool_provider" "this" {
  # An attribute condition is a Common Expression Language (CEL) expression that can check assertion attributes and
  # target attributes. If the attribute condition evaluates to true for a given credential, the credential is accepted.
  # Otherwise, the credential is rejected.
  #
  # Some of the claims embedded in the GitHub Actions OIDC token are not guaranteed to be unique, and tokens issued by
  # other GitHub organizations or repositories may contain the same values, allowing them to establish an identity.
  # To protect against this situation, always use an attribute condition to restrict access to tokens issued by your
  # GitHub organization.
  #
  # GitHub guarantees the following ID to be unique and never re-used. This will protect against cybersquatting attacks.
  #
  # To get the organization id, you can run the following curl command with a token that has the read:org scope against
  # your existing organization:
  #
  # curl -H "Authorization: token $GITHUB_READ_ORG_TOKEN" https://api.github.com/orgs/osinfra-io
  attribute_condition = local.github_actions_attribute_condition

  # The tokens issued by your external identity provider contain one or more attributes. Some identity providers refer
  # to these attributes as claims. An attribute mapping defines how to derive the value of the Google STS token attribute
  # from an external token.
  attribute_mapping = {
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }

  description  = "Workload Identity Pool Provider for GitHub Actions"
  display_name = "GitHub Actions OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  project                            = module.google_project.id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-oidc"
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
  member        = local.cloud_storage_service_account_member
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "github_actions" {
  for_each = local.opentofu_state_management

  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = local.github_actions_members[each.key]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_kms_crypto_key_iam_member" "logos_state_readers" {
  crypto_key_id = google_kms_crypto_key.state_encryption.id
  member        = local.logos_state_readers_member
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
  for_each = module.google_project_platform_managed

  member  = local.container_engine_robot_members[each.key]
  project = module.google_project.id
  role    = "organizations/163313809793/roles/kubernetes.hostFirewallManagement"
}

resource "google_project_iam_member" "container_engine_service_agent_user" {
  for_each = module.google_project_platform_managed

  member  = local.container_engine_robot_members[each.key]
  project = module.google_project.id
  role    = "roles/container.hostServiceAgentUser"
}

# DNS Records Admin for Teams with GKE Clusters
# Teams with Kubernetes clusters need to manage DNS records for their Istio gateways.

resource "google_project_iam_member" "dns_records_admins_gke_teams" {
  for_each = local.dns_records_admins_gke_teams

  member  = local.github_actions_members[each.key]
  project = module.google_project.id
  role    = "organizations/163313809793/roles/dns.recordsAdmin"
}

# Google Project Owners
# Grant team service accounts owner role on their google_projects.

resource "google_project_iam_member" "google_project_owners" {
  for_each = local.google_project_owners

  member  = local.github_actions_members[each.value.team_key]
  project = module.google_project_teams[each.key].id
  role    = "roles/owner"
}

resource "google_project_iam_member" "multi_cluster_service_agents" {
  for_each = local.teams_with_gke_hub_host

  member  = local.multi_cluster_service_agent_members[each.key]
  project = module.google_project.id
  role    = "roles/multiclusterservicediscovery.serviceAgent"
}

# Platform-Managed Project Owners
# Grant team service accounts owner role on their platform-managed projects.

resource "google_project_iam_member" "platform_managed_project_owners" {
  for_each = local.platform_managed_project_owners

  member  = local.github_actions_members[each.key]
  project = module.google_project_platform_managed[each.key].id
  role    = "roles/owner"
}

# Platform-Managed Project Pneuma Owners
# Grant the pt-pneuma service account owner role on all other teams' platform-managed projects
# so pt-pneuma can provision and manage GKE clusters on behalf of all teams.

resource "google_project_iam_member" "platform_managed_project_pneuma_owners" {
  for_each = local.gke_teams_for_pneuma_access

  member  = local.github_actions_members["pt-pneuma"]
  project = module.google_project_platform_managed[each.key].id
  role    = "roles/owner"
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

  account_id   = each.value.account_id
  display_name = "Service account for GitHub Actions"
  project      = module.google_project.id
}

# Google Service Account IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_service_account_iam#google_service_account_iam_member

resource "google_service_account_iam_member" "github_actions" {
  for_each = local.github_repositories

  member             = each.value.member
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
  member = local.github_actions_members[each.key]
  role   = "roles/storage.objectAdmin"
}

resource "google_storage_bucket_iam_member" "logos_state_readers" {
  bucket = module.google_storage_bucket["pt-logos"].name
  member = local.logos_state_readers_member
  role   = "roles/storage.objectViewer"
}

# Datadog Google Cloud Platform Integration Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-datadog-google-integration

module "datadog_google_integration" {
  lifecycle {
    enabled = var.datadog_enable
  }

  source = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=329a3c3120b8060d4492cab68618dd8579ff7355" # v0.4.2

  api_key                            = var.datadog_api_key
  enable_cloud_cost_management       = local.enable_cloud_cost_management
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.core_helpers.labels
  project                            = module.google_project.id
}

# Datadog Google Cloud Platform Integration for Additional Google Projects
# https://github.com/osinfra-io/pt-arche-datadog-google-integration

module "datadog_google_integration_datadog_projects" {
  for_each = local.datadog_google_project_for_each
  source   = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=329a3c3120b8060d4492cab68618dd8579ff7355" # v0.4.2

  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true

  labels = merge(
    module.core_helpers.labels,
    {
      team = each.value.team_key
    }
  )

  project = module.google_projects[each.key].id
}

# Datadog Google Cloud Platform Integration for Kubernetes Projects
# https://github.com/osinfra-io/pt-arche-datadog-google-integration

module "datadog_google_integration_kubernetes_projects" {
  for_each = local.datadog_kubernetes_for_each
  source   = "github.com/osinfra-io/pt-arche-datadog-google-integration?ref=329a3c3120b8060d4492cab68618dd8579ff7355" # v0.4.2

  api_key                            = var.datadog_api_key
  is_cspm_enabled                    = true
  is_security_command_center_enabled = true
  labels                             = module.core_helpers.labels
  project                            = module.google_project_kubernetes[each.key].id
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_osinfra_io_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=7e7a565fe9f63f0c2367272da5d301d1154731de" # v0.3.3

  dns_name   = local.osinfra_io_dns_zone_name
  labels     = module.core_helpers.labels
  name       = local.osinfra_io_dns_name
  project    = module.google_project.id
  visibility = "public"
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_private_dns" {
  source = "github.com/osinfra-io/pt-arche-google-network//dns?ref=7e7a565fe9f63f0c2367272da5d301d1154731de" # v0.3.3

  dns_name = local.private_dns_zone_name
  labels   = module.core_helpers.labels
  name     = local.private_dns_name

  private_visibility_config_networks = [
    module.google_network_vpc.self_link
  ]

  project    = module.google_project.id
  visibility = "private"
}

# Google Cloud DNS Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_team_dns" {
  for_each = local.teams_with_dns_zones
  source   = "github.com/osinfra-io/pt-arche-google-network//dns?ref=7e7a565fe9f63f0c2367272da5d301d1154731de" # v0.3.3

  dns_name = each.value.dns_name

  labels = merge(
    module.core_helpers.labels,
    {
      team = each.key
    }
  )

  name       = each.value.name
  project    = module.google_project.id
  visibility = "public"
}

# Google VPC Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-vpc

module "google_network_vpc" {
  source = "github.com/osinfra-io/pt-arche-google-network?ref=7e7a565fe9f63f0c2367272da5d301d1154731de" # v0.3.3

  name       = "standard-shared"
  project    = module.google_project.id
  shared_vpc = true
}

# Google Project Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-project

module "google_project" {
  source = "github.com/osinfra-io/pt-arche-google-project?ref=885f309e179482619300f458bb2b6ec4ac1cdb94" # v0.6.8

  billing_account       = var.project_billing_account
  deletion_policy       = "DELETE"
  description           = module.core_helpers.project_naming.description
  folder_id             = module.core_helpers.environment_folder_id
  labels                = module.core_helpers.labels
  monthly_budget_amount = var.project_monthly_budget_amount
  prefix                = module.core_helpers.project_naming.prefix

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

# Google Kubernetes Project Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-project
# Create Kubernetes projects for teams with google_kubernetes_engine_clusters

module "google_project_kubernetes" {
  for_each = local.teams_with_gke_clusters
  source   = "github.com/osinfra-io/pt-arche-google-project?ref=885f309e179482619300f458bb2b6ec4ac1cdb94" # v0.6.8

  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = module.google_project.id
  deletion_policy                 = "DELETE"
  description                     = "k8s"
  folder_id                       = module.core_helpers.teams[each.key].environments[local.environment_key]

  labels = merge(
    module.core_helpers.labels,
    {
      team = each.key
    }
  )

  monthly_budget_amount = var.kubernetes_project_monthly_budget_amount
  prefix                = each.key

  services = concat(
    [
      "billingbudgets.googleapis.com",
      "certificatemanager.googleapis.com",
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

# Google Project Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-project

module "google_projects" {
  for_each = local.google_projects
  source   = "github.com/osinfra-io/pt-arche-google-project?ref=885f309e179482619300f458bb2b6ec4ac1cdb94" # v0.6.8

  billing_account                 = var.project_billing_account
  cis_2_2_logging_sink_project_id = module.google_project.id
  deletion_policy                 = "DELETE"
  description                     = each.value.description
  folder_id                       = module.core_helpers.teams[each.value.team_key].environments[local.environment_key]

  labels = merge(
    module.core_helpers.labels,
    {
      team = each.value.team_key
    }
  )

  monthly_budget_amount = var.project_monthly_budget_amount
  prefix                = each.value.team_key
  services              = each.value.services
}

# Google Storage Bucket Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-storage-bucket

module "google_storage_bucket" {
  for_each = local.opentofu_state_management
  source   = "github.com/osinfra-io/pt-arche-google-storage-bucket?ref=06fed4c18033a3f458e42458889d5b920c68f3eb" # v0.3.2

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

  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  description                        = "Workload Identity Pool Provider for ${each.value.display_name}"
  disabled                           = lookup(each.value, "disabled", false)
  display_name                       = "${each.value.display_name} OIDC"
  project                            = module.google_project.id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "${each.key}-oidc"

  oidc {
    allowed_audiences = lookup(each.value, "allowed_audiences", [])
    issuer_uri        = each.value.issuer_uri
  }
}

# Google KMS Crypto Key Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/kms_crypto_key

resource "google_kms_crypto_key" "state_encryption" {
  # CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed CryptoKey will
  # remove it from state and delete all CryptoKeyVersions, rendering the key unusable, but will not delete
  # the resource from the project. When OpenTofu destroys these keys, any data previously encrypted with
  # these keys will be irrecoverable. For this reason, it is strongly recommended that you add lifecycle
  # hooks to the resource to prevent accidental destruction.

  # We can't use the lifecycle block to prevent destroy on this resource for testing purposes.

  # lifecycle {
  #   prevent_destroy = true
  # }

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
  # We can't use the lifecycle block to prevent destroy on this resource for testing purposes.

  # KeyRings cannot be deleted from Google Cloud Platform. Destroying a OpenTofu-managed KeyRing will remove it from
  # state but will not delete the resource from the project.

  # lifecycle {
  #   prevent_destroy = true
  # }

  location = "us"
  name     = "state-encryption"
  project  = module.google_project.id
}

# Project IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_project_iam_member

resource "google_project_iam_member" "container_engine_firewall_management" {
  for_each = local.vpc_service_projects_kubernetes

  member  = "serviceAccount:service-${each.value.number}@container-engine-robot.iam.gserviceaccount.com"
  project = module.google_project.id
  role    = "organizations/163313809793/roles/kubernetes.hostFirewallManagement"
}

resource "google_project_iam_member" "container_engine_service_agent_user" {
  for_each = local.vpc_service_projects_kubernetes

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
  project = module.google_projects[each.key].id
  role    = "roles/owner"
}

# Kubernetes Project Owners
# Grant team service accounts owner role on their kubernetes_projects.

resource "google_project_iam_member" "kubernetes_project_owners" {
  for_each = local.gke_teams_with_service_accounts

  member  = "serviceAccount:${google_service_account.github_actions[each.key].email}"
  project = module.google_project_kubernetes[each.key].id
  role    = "roles/owner"
}

resource "google_project_iam_member" "multi_cluster_service_agents" {
  for_each = local.teams_with_gke_hub_host

  member  = "serviceAccount:${google_project_service_identity.multi_cluster_service_agents[each.key].email}"
  project = module.google_project.id
  role    = "roles/multiclusterservicediscovery.serviceAgent"
}

# Multi-Cluster Service Discovery IAM Binding
# Required for MCS setup with Shared VPC
# https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-services/setup#shared-vpc

resource "google_project_service_identity" "multi_cluster_service_agents" {
  depends_on = [module.google_project_kubernetes]
  for_each   = local.teams_with_gke_hub_host
  provider   = google-beta # Required for google_project_service_identity

  project = module.google_project_kubernetes[each.key].id
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

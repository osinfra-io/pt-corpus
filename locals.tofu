# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Billing users manager role for_each
  # Determines whether each service account gets the MANAGER role in the billing users group.
  # Only the pt-corpus service account is granted MANAGER; all other teams get an empty list (MEMBER only).
  billing_users_manager_for_each = {
    for k, v in local.service_accounts : k => k == "pt-corpus" ? [1] : []
  }

  # Browsers group name
  # The pt-corpus browsers identity group for the current environment
  browsers_group_name = module.core_helpers.teams["pt-corpus"].identity_groups["${lower(local.environment_key)}-browsers"].name

  # Cloud Storage service agent member
  cloud_storage_service_account_member = "serviceAccount:service-${module.google_project.number}@gs-project-accounts.iam.gserviceaccount.com"

  # Container Engine robot members
  # Keyed by team; the GKE service agent of each platform-managed project
  container_engine_robot_members = {
    for k, v in module.google_project_platform_managed : k => "serviceAccount:service-${v.number}@container-engine-robot.iam.gserviceaccount.com"
  }

  # Datadog integration for_each maps
  # Empty unless Datadog is enabled
  datadog_platform_managed_projects = var.datadog_enable ? local.teams_with_platform_managed_datadog : {}
  datadog_team_projects             = var.datadog_enable ? local.google_projects_with_datadog : {}

  # DNS records admin for teams with GKE clusters
  dns_records_admins_gke_teams = {
    for k, v in local.teams_with_platform_managed_projects : k => v
    if contains(keys(local.service_accounts), k) && length(v.platform_managed_project.kubernetes_engine_locations) > 0
  }

  # Enable Cloud Cost Management only in production
  enable_cloud_cost_management = module.core_helpers.env == "prod"

  # Enable the Docker Hub remote registry when any team has an Artifact Registry
  enable_docker_remote_registry = length(local.teams_with_artifact_registries) > 0

  # Environment key for logos lookup (title case with hyphens preserved)
  # Converts workspace environment (e.g., "non-production") to logos format (e.g., "Non-Production")
  environment_key = title(module.core_helpers.environment)

  # GitHub Actions WIF provider attribute condition
  github_actions_attribute_condition = module.core_helpers.env == "sb" ? "assertion.repository_owner_id==\"104685378\"" : "assertion.repository_owner_id==\"104685378\" && (${join(" || ", local.github_actions_ref_conditions)})"

  # GitHub Actions service account members
  github_actions_members = {
    for k, sa in google_service_account.github_actions : k => "serviceAccount:${sa.email}"
  }

  # CEL ref assertions for the github-actions WIF provider (non-sandbox only).
  # Add entries here to permit additional refs (e.g. release tags).
  github_actions_ref_conditions = module.core_helpers.env == "sb" ? [] : [
    "assertion.ref == \"refs/heads/main\"",
    "assertion.ref.startsWith(\"refs/tags/\")",
  ]

  # GitHub Repositories
  # Create a map of repositories for workload identity bindings
  github_repositories = {
    for item in flatten([
      for team_key, team in module.core_helpers.teams : [
        for repo_key, repo in team.github_repositories : {
          member     = "principalSet://iam.googleapis.com/projects/${module.google_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.this.workload_identity_pool_id}/attribute.repository/osinfra-io/${repo_key}"
          name       = team_key
          repository = repo_key
          team_key   = team_key
        }
        if repo.enable_google_wif_service_account
      ]
      if team.enable_workflows
    ]) : item.repository => item
  }

  # GKE teams for pneuma access
  # Platform-managed teams with GKE clusters (excluding pt-pneuma itself) whose platform-managed projects
  # pt-pneuma must access to provision and manage GKE clusters on their behalf
  gke_teams_for_pneuma_access = {
    for k, v in local.teams_with_platform_managed_projects : k => v
    if k != "pt-pneuma" && length(v.platform_managed_project.kubernetes_engine_locations) > 0
  }

  # Google project owners
  # Team service accounts that own their Google projects
  google_project_owners = {
    for k, v in local.google_projects : k => v if contains(keys(local.service_accounts), k)
  }

  # Google Projects
  # Teams that have opted in to a Google Cloud project
  google_projects = {
    for team_key, team in module.core_helpers.teams :
    team_key => {
      enable_datadog = team.google_project_enable_datadog
      services       = team.google_project_services
      team_key       = team_key
    }
    if team.enable_workflows && team.enable_google_project
  }

  # Google Projects with Datadog enabled
  # Subset of google_projects where the team has opted in to Datadog integration
  google_projects_with_datadog = {
    for key, project in local.google_projects :
    key => project
    if project.enable_datadog
  }

  # Logos state readers group member
  logos_state_readers_member = "group:${module.core_helpers.teams["pt-logos"].identity_groups["state-readers"].email}"

  # Multi-cluster service agent members
  multi_cluster_service_agent_members = {
    for k, v in google_project_service_identity.multi_cluster_service_agents : k => "serviceAccount:${v.email}"
  }

  # Non-corpus service accounts
  # Service accounts for teams other than pt-corpus, used for browser and state reader group memberships
  non_corpus_service_accounts = {
    for k, v in local.service_accounts : k => v if k != "pt-corpus"
  }

  # OpenTofu State Management
  # Create a map of teams that need OpenTofu state management infrastructure (state bucket, KMS, storage IAM)
  opentofu_state_management = {
    for team_key, team in module.core_helpers.teams :
    team_key => {
      bucket_name = "${team_key}-state-${module.core_helpers.env}"
    }
    if team.enable_opentofu_state_management && team.enable_workflows
  }

  # osinfra.io DNS zone name and DNS name
  # Constructs the environment-level public zone identifier (e.g., osinfra.io in prod, sb.osinfra.io in sandbox)
  osinfra_io_dns_name      = module.core_helpers.env == "prod" ? "osinfra-io" : "${module.core_helpers.env}-osinfra-io"
  osinfra_io_dns_zone_name = module.core_helpers.env == "prod" ? "osinfra.io." : "${module.core_helpers.env}.osinfra.io."

  # osinfra.io NS delegations
  # Keyed by delegation name, with the trailing dot required for the record name
  osinfra_io_ns_delegations = {
    for delegation in var.osinfra_io_ns_delegations : delegation.name => {
      managed_zone = delegation.managed_zone
      name         = "${delegation.name}."
      rrdatas      = delegation.rrdatas
      ttl          = delegation.ttl
    }
  }

  # Output values
  output_platform_managed_projects = {
    for team_key, project in module.google_project_platform_managed :
    team_key => {
      cloud_sql   = module.core_helpers.teams[team_key].platform_managed_project.cloud_sql
      environment = module.core_helpers.env
      id          = project.id
      number      = project.number
      team        = team_key
    }
  }

  output_private_dns_zone = {
    dns_name = local.private_dns_zone_name
    name     = local.private_dns_name
  }

  output_service_accounts = {
    for key, sa in google_service_account.github_actions :
    key => {
      email     = sa.email
      name      = sa.name
      unique_id = sa.unique_id
    }
  }

  output_storage_buckets = {
    for key, bucket in module.google_storage_bucket :
    key => {
      name = bucket.name
      url  = bucket.url
    }
  }

  output_teams = {
    for team_key, team in module.core_helpers.teams :
    team_key => merge(team, {
      google_project = contains(keys(module.google_project_teams), team_key) ? {
        id = module.google_project_teams[team_key].id
      } : null

      platform_managed_project = contains(keys(module.google_project_platform_managed), team_key) ? {
        environment = module.core_helpers.env
        id          = module.google_project_platform_managed[team_key].id
        number      = module.google_project_platform_managed[team_key].number
      } : null
    })
  }

  output_workload_identity_pools = {
    (google_iam_workload_identity_pool.this.workload_identity_pool_id) = {
      name                      = google_iam_workload_identity_pool.this.name
      workload_identity_pool_id = google_iam_workload_identity_pool.this.workload_identity_pool_id
    }
  }

  output_workload_identity_providers = {
    (google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id) = {
      name                               = google_iam_workload_identity_pool_provider.this.name
      workload_identity_pool_provider_id = google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id
    }
  }

  # Platform-managed project labels
  platform_managed_project_labels = {
    for k, v in local.team_labels : k => merge(v, { "project-type" = "platform-managed" })
  }

  # Platform-managed project owners
  # Team service accounts that own their platform-managed projects
  platform_managed_project_owners = {
    for k, v in local.teams_with_platform_managed_projects : k => v if contains(keys(local.service_accounts), k)
  }

  # Platform-managed project services
  # Constructs the list of services for each platform-managed project, conditionally appending GKE Hub services
  platform_managed_project_services = {
    for k, v in local.teams_with_platform_managed_projects : k => concat(
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
        "pubsub.googleapis.com",
        "securitycenter.googleapis.com",
        "serviceusage.googleapis.com",
        "trafficdirector.googleapis.com"
      ],
      contains(keys(local.teams_with_cloud_sql), k) ? ["servicenetworking.googleapis.com", "sqladmin.googleapis.com"] : [],
      v.has_gke_hub_host ? [
        "gkehub.googleapis.com",
        "multiclusteringress.googleapis.com"
      ] : []
    )
  }

  # Private DNS zone name and DNS name
  # Used by the private DNS module to construct environment-specific zone identifiers
  private_dns_name      = module.core_helpers.env == "prod" ? "gcp-priv-osinfra-io" : "gcp-priv-${module.core_helpers.env}-osinfra-io"
  private_dns_zone_name = module.core_helpers.env == "prod" ? "gcp.priv.osinfra.io." : "gcp.priv.${module.core_helpers.env}.osinfra.io."

  # Regional subnets
  # Organize subnets by region for regional deployments, enriched with platform-managed project numbers
  regional_subnets = {
    for region in distinct([for k, v in local.team_subnets : v.region]) :
    region => {
      for subnet_key, subnet in local.team_subnets :
      subnet_key => merge(subnet, {
        service_project_number = module.google_project_platform_managed[subnet.team_key].number
      })
      if subnet.region == region
    }
  }

  # Service Accounts
  # Create service accounts based on teams that have workflows enabled
  service_accounts = {
    for team_key, team in module.core_helpers.teams :
    team_key => {
      account_id          = "${team_key}-github"
      github_repositories = team.github_repositories
    }
    if team.enable_workflows
  }

  # Team DNS Subdomains
  # Resolves the DNS subdomain for each team: uses dns_subdomain if set (e.g., "pneuma"),
  # otherwise derives it from the team key by stripping the org prefix (e.g., pt-pneuma → pneuma).
  team_dns_subdomains = {
    for team_key, team in module.core_helpers.teams :
    team_key => team.dns_subdomain != null ? team.dns_subdomain : replace(team_key, "/^[a-z]+-/", "")
    if length(try(team.platform_managed_project.kubernetes_engine_locations, {})) > 0
  }

  # Team labels
  # Maps team keys to labels, merging core_helpers labels with the team key
  team_labels = { for k, v in module.core_helpers.teams : k => merge(module.core_helpers.labels, { team = k }) }

  # Team project services
  # Constructs the list of services for each team project, merging the required baseline with per-team
  # additional services sourced from pt-logos team configuration
  team_project_services = {
    for k, v in local.google_projects : k => concat(
      [
        "billingbudgets.googleapis.com",
        "cloudasset.googleapis.com",
        "cloudbilling.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "compute.googleapis.com",
        "iam.googleapis.com",
        "monitoring.googleapis.com",
        "pubsub.googleapis.com",
        "securitycenter.googleapis.com",
        "serviceusage.googleapis.com",
      ],
      v.services
    )
  }

  # Team subnets
  # Extract subnet configurations from cluster definitions in all teams, preserving team association.
  # Keyed by derived cluster name ({team_key}-{location}).
  # Region is extracted from the location key by stripping the zone suffix (e.g., us-east1-b → us-east1).
  team_subnets = merge([
    for team_key, team in module.core_helpers.teams : {
      for location, cluster in try(team.platform_managed_project.kubernetes_engine_locations, {}) :
      "${team_key}-${location}" => merge(cluster.subnet, {
        region   = regex("^(us-[a-z]+[0-9]+)-[a-z]$", location)[0]
        team_key = team_key
      })
    }
  ]...)

  # Teams with Artifact Registries
  # Teams that have kubernetes.artifact_registry_groups_memberships defined in pt-logos
  teams_with_artifact_registries = {
    for team_key, team in module.core_helpers.teams :
    team_key => {
      registry_readers = concat(
        [
          "group:${team.identity_groups["registry-readers"].email}"
        ],
        # GKE Hub hosts serve member clusters that pull images from the hub team's registry
        # (e.g. Istio images). Include the registry-readers group of every other team with
        # a platform-managed project so their node SAs (which join that group) have access.
        try(local.teams_with_platform_managed_projects[team_key].has_gke_hub_host, false) ? [
          for k, other_team in local.teams_with_platform_managed_projects :
          "group:${module.core_helpers.teams[k].identity_groups["registry-readers"].email}"
          if k != team_key && contains(keys(module.core_helpers.teams[k].identity_groups), "registry-readers")
        ] : []
      )
      registry_writers = [
        "group:${team.identity_groups["registry-writers"].email}"
      ]
      standard_description   = "Registry for multi-region - US Standard : ${team_key}"
      standard_repository_id = "${team_key}-standard"
      virtual_description    = "Registry for multi-region - US Virtual : ${team_key}"
      virtual_repository_id  = "${team_key}-virtual"
    }
    if contains(keys(team.identity_groups), "registry-readers") &&
    contains(keys(team.identity_groups), "registry-writers") &&
    team.enable_workflows
  }

  # Teams with Cloud SQL
  # Teams that have opted in to at least one Cloud SQL instance in their platform-managed project
  teams_with_cloud_sql = {
    for team_key, team in local.teams_with_platform_managed_projects :
    team_key => team
    if length(try(team.platform_managed_project.cloud_sql, {})) > 0
  }

  # Teams with DNS Zones
  # Creates DNS zone configurations for teams with Kubernetes clusters.
  # Zone naming is env-first: prod → pneuma.osinfra.io, sb → pneuma.sb.osinfra.io, nonprod → pneuma.nonprod.osinfra.io.
  teams_with_dns_zones = {
    for team_key, team in module.core_helpers.teams :
    team_key => {
      dns_name = module.core_helpers.env == "prod" ? "${local.team_dns_subdomains[team_key]}.osinfra.io." : "${local.team_dns_subdomains[team_key]}.${module.core_helpers.env}.osinfra.io."
      name     = module.core_helpers.env == "prod" ? "${local.team_dns_subdomains[team_key]}-osinfra-io" : "${local.team_dns_subdomains[team_key]}-${module.core_helpers.env}-osinfra-io"
    }
    if length(try(team.platform_managed_project.kubernetes_engine_locations, {})) > 0
  }

  # Teams with GKE Hub Host
  # Subset of teams_with_platform_managed_projects where the team has a GKE Hub host cluster
  teams_with_gke_hub_host = {
    for team_key, team in local.teams_with_platform_managed_projects :
    team_key => team
    if team.has_gke_hub_host
  }

  # Teams with platform-managed projects
  # Identify teams that need platform-managed projects (GKE clusters, data services, etc.)
  teams_with_platform_managed_projects = {
    for team_key, team in module.core_helpers.teams :
    team_key => merge(team, {
      # Check if any cluster in this team has enable_gke_hub_host = true
      has_gke_hub_host = anytrue([
        for location, cluster in team.platform_managed_project.kubernetes_engine_locations :
        lookup(cluster, "enable_gke_hub_host", false)
      ])
    })
    if team.platform_managed_project != null
  }

  # Teams with platform-managed Datadog enabled
  # Subset of teams_with_platform_managed_projects where the team has opted in to Datadog integration
  teams_with_platform_managed_datadog = {
    for team_key, team in local.teams_with_platform_managed_projects :
    team_key => team
    if team.enable_platform_managed_datadog
  }

  # VPC Service Projects
  # Automatically include all platform-managed projects as VPC service projects
  # Merges manually configured service projects with platform-managed projects
  # Keys must be statically known at plan time, so team_key is used instead of project.id
  vpc_service_projects = merge(
    {
      for team_key, project in module.google_project_platform_managed :
      team_key => {
        id     = project.id
        number = project.number
      }
    },
    {
      for project_id, project in var.vpc_service_projects :
      project_id => {
        id     = project_id
        number = project.number
      }
    }
  )
}

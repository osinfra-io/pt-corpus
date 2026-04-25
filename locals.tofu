# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Billing users group - centrally managed in pt-logos, referenced here for membership management
  billing_users_group_name = module.core_helpers.teams["pt-logos"].billing_users_group.name

  # Billing users manager role for_each
  # Determines whether each service account gets the MANAGER role in the billing users group.
  # Only the pt-corpus service account is granted MANAGER; all other teams get an empty list (MEMBER only).
  billing_users_manager_for_each = {
    for k, v in local.service_accounts : k => k == "pt-corpus" ? [1] : []
  }

  # Browser group - centrally managed in pt-logos, referenced here for membership management
  browser_group_name = module.core_helpers.teams["pt-corpus"].identity_groups["${lower(local.environment_key)}-browsers"].name

  # Datadog Google project for_each
  # Resolves the for_each for the google_project_datadog module: enabled only when var.datadog_enable is true
  datadog_google_project_for_each = var.datadog_enable ? local.google_projects_with_datadog : {}

  # Datadog platform-managed for_each
  # Resolves the for_each for the platform_managed_datadog module: enabled only when var.datadog_enable is true
  datadog_platform_managed_for_each = var.datadog_enable ? local.teams_with_platform_managed_datadog : {}

  # Enable Cloud Cost Management only in production
  enable_cloud_cost_management = module.core_helpers.env == "prod"

  # Environment key for logos lookup (title case with hyphens preserved)
  # Converts workspace environment (e.g., "non-production") to logos format (e.g., "Non-Production")
  environment_key = title(module.core_helpers.environment)

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

  # GKE teams with service accounts
  # Subset of teams_with_platform_managed_projects filtered to those with GKE clusters and a corresponding service account
  gke_teams_with_service_accounts = {
    for k, v in local.teams_with_platform_managed_projects : k => v
    if contains(keys(local.service_accounts), k) && length(v.platform_managed_project.kubernetes_engine_locations) > 0
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

  # Google projects with service accounts
  # Subset of google_projects filtered to those whose team has a corresponding service account
  google_projects_with_service_accounts = {
    for k, v in local.google_projects : k => v if contains(keys(local.service_accounts), k)
  }

  # Logos state readers group - centrally managed in pt-logos, referenced here for membership management
  logos_state_readers_group_name = module.core_helpers.teams["pt-logos"].identity_groups["state-readers"].name

  # Non-corpus service accounts
  # Service accounts for teams other than pt-corpus, used for browser and state reader group memberships
  non_corpus_service_accounts = {
    for k, v in local.service_accounts : k => v if k != "pt-corpus"
  }

  # OpenTofu State Management
  # Create a map of teams that need OpenTofu state management infrastructure (state bucket, KMS, storage IAM)
  opentofu_state_management = {
    for team_key, team in module.core_helpers.teams :
    team_key => {}
    if team.enable_opentofu_state_management && team.enable_workflows
  }

  # osinfra.io DNS zone name and DNS name
  # Constructs the environment-level public zone identifier (e.g., osinfra.io in prod, sb.osinfra.io in sandbox)
  osinfra_io_dns_name      = module.core_helpers.env == "prod" ? "osinfra-io" : "${module.core_helpers.env}-osinfra-io"
  osinfra_io_dns_zone_name = module.core_helpers.env == "prod" ? "osinfra.io." : "${module.core_helpers.env}.osinfra.io."

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
      contains(keys(local.teams_with_cloud_sql), k) ? ["sqladmin.googleapis.com"] : [],
      v.has_gke_hub_host ? [
        "gkehub.googleapis.com",
        "multiclusteringress.googleapis.com"
      ] : []
    )
  }

  # Platform-managed teams with service accounts
  # All teams with platform-managed projects (GKE or data services) that also have a service account
  platform_managed_teams_with_service_accounts = {
    for k, v in local.teams_with_platform_managed_projects : k => v
    if contains(keys(local.service_accounts), k)
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
    if length(team.platform_managed_project.kubernetes_engine_locations) > 0
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
      for location, cluster in team.platform_managed_project.kubernetes_engine_locations :
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
      registry_readers = [
        "group:${team.identity_groups["registry-readers"].email}",
        "serviceAccount:${module.google_project_platform_managed[team_key].number}-compute@developer.gserviceaccount.com"
      ]
      registry_writers = [
        "group:${team.identity_groups["registry-writers"].email}"
      ]
    }
    if contains(keys(team.identity_groups), "registry-readers") &&
    contains(keys(team.identity_groups), "registry-writers") &&
    team.enable_workflows
  }

  # Teams with Cloud SQL
  # Teams that have opted in to Cloud SQL in their platform-managed project
  teams_with_cloud_sql = {
    for team_key, team in local.teams_with_platform_managed_projects :
    team_key => team
    if try(team.platform_managed_project.cloud_sql != null, false)
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
    if length(team.platform_managed_project.kubernetes_engine_locations) > 0
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
    if team.has_platform_managed_project
  }

  # Teams with GKE Hub Host
  # Subset of teams_with_platform_managed_projects where the team has a GKE Hub host cluster
  teams_with_gke_hub_host = {
    for team_key, team in local.teams_with_platform_managed_projects :
    team_key => team
    if team.has_gke_hub_host
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

  # VPC Service Projects for platform-managed
  # Only platform-managed projects that need GKE-specific IAM permissions
  # Keys must be statically known at plan time, so team_key is used instead of project.id
  vpc_service_projects_platform_managed = {
    for team_key, project in module.google_project_platform_managed :
    team_key => {
      id     = project.id
      number = project.number
    }
  }

  # Workload Identity
  # Configuration for external identity provider authentication

  workload_identity = {

    "github-actions" = {

      # An attribute condition is a Common Expression Language (CEL) expression that can check assertion attributes and
      # target attributes. If the attribute condition evaluates to true for a given credential, the credential is accepted.
      # Otherwise, the credential is rejected.

      # Some of the claims embedded in the GitHub Actions OIDC token are not guaranteed to be unique, and tokens issued by
      # other GitHub organizations or repositories may contain the same values, allowing them to establish an identity.
      # To protect against this situation, always use an attribute condition to restrict access to tokens issued by your
      # GitHub organization.

      # GitHub guarantees the following ID to be unique and never re-used. This will protect against cybersquatting attacks.

      # To get the organization id, you can run the following curl command with a token that has the read:org scope against
      # your existing organization:

      # curl -H "Authorization: token $GITHUB_READ_ORG_TOKEN" https://api.github.com/orgs/osinfra-io

      attribute_condition = module.core_helpers.env == "sb" ? "assertion.repository_owner_id==\"104685378\"" : "assertion.repository_owner_id==\"104685378\" && (${join(" || ", local.github_actions_ref_conditions)})"

      # The tokens issued by your external identity provider contain one or more attributes. Some identity providers refer
      # to these attributes as claims. An attribute mapping defines how to derive the value of the Google STS token attribute
      # from an external token.

      attribute_mapping = {
        "attribute.repository" = "assertion.repository"
        "google.subject"       = "assertion.sub"
      }

      display_name = "GitHub Actions"
      issuer_uri   = "https://token.actions.githubusercontent.com"
    }
  }
}

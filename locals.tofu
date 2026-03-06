# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Billing users group - centrally managed in pt-logos, referenced here for membership management
  billing_users_group_name = module.helpers.teams["pt-logos"].billing_users_group.name

  # Browser group - centrally managed in pt-logos, referenced here for membership management
  browser_group_name = module.helpers.teams["pt-corpus"].identity_groups["${lower(local.environment_key)}-browser"].name

  # Environment key for logos lookup (title case with hyphens preserved)
  # Converts workspace environment (e.g., "non-production") to logos format (e.g., "Non-Production")
  environment_key = title(module.helpers.environment)

  # Flattened subnets
  # Transform regional subnet maps into flat map with region metadata
  flattened_subnets = merge([
    for region, subnets in local.team_subnets : {
      for subnet_name, subnet in subnets :
      subnet_name => merge(subnet, {
        region = region
      })
    }
  ]...)

  # GitHub Repositories
  # Create a map of repositories for workload identity bindings
  github_repositories = {
    for item in flatten([
      for team_key, team in module.helpers.teams : [
        for repo_key, repo in team.github_repositories : {
          name       = team_key
          repository = repo_key
          team_key   = team_key
        }
      ]
    ]) : item.repository => item
  }

  # osinfra.io DNS zone name and DNS name
  # Constructs the environment-level public zone identifier (e.g., osinfra.io in prod, sb.osinfra.io in sandbox)
  osinfra_io_dns_name      = module.helpers.env == "prod" ? "osinfra-io" : "${module.helpers.env}-osinfra-io"
  osinfra_io_dns_zone_name = module.helpers.env == "prod" ? "osinfra.io." : "${module.helpers.env}.osinfra.io."

  # Private DNS zone name and DNS name
  # Used by the private DNS module to construct environment-specific zone identifiers
  private_dns_name      = module.helpers.env == "prod" ? "gcp-priv-osinfra-io" : "gcp-priv-${module.helpers.env}-osinfra-io"
  private_dns_zone_name = module.helpers.env == "prod" ? "gcp.priv.osinfra.io." : "gcp.priv.${module.helpers.env}.osinfra.io."

  # Regional subnets
  # Organize subnets by region for regional deployments, enriched with Kubernetes project numbers
  regional_subnets = {
    for region in distinct([for k, v in local.team_subnets : v.region]) :
    region => {
      for subnet_key, subnet in local.team_subnets :
      subnet_key => merge(subnet, {
        service_project_number = module.kubernetes_projects[subnet.team_key].number
      })
      if subnet.region == region
    }
  }

  # Service Accounts
  # Create service accounts based on teams that have GitHub repositories
  service_accounts = {
    for team_key, team in module.helpers.teams :
    team_key => {
      github_repositories = team.github_repositories
    }
    if length(team.github_repositories) > 0
  }

  # Teams with Artifact Registries
  # Teams that have kubernetes.artifact_registry_groups_memberships defined in pt-logos
  teams_with_artifact_registries = {
    for team_key, team in module.helpers.teams :
    team_key => {
      registry_readers = [
        "group:${team.identity_groups["registry-readers"].email}",
        "serviceAccount:${module.kubernetes_projects[team_key].number}-compute@developer.gserviceaccount.com"
      ]
      registry_writers = [
        "group:${team.identity_groups["registry-writers"].email}"
      ]
    }
    if contains(keys(team.identity_groups), "registry-readers") &&
    contains(keys(team.identity_groups), "registry-writers")
  }

  # Team DNS Subdomains
  # Resolves the DNS subdomain for each team: uses dns_subdomain if set (e.g., "pneuma"),
  # otherwise derives it from the team key by stripping the org prefix (e.g., pt-pneuma → pneuma).
  team_dns_subdomains = {
    for team_key, team in module.helpers.teams :
    team_key => team.dns_subdomain != null ? team.dns_subdomain : replace(team_key, "/^[a-z]+-/", "")
    if team.google_kubernetes_engine_clusters != null && length(team.google_kubernetes_engine_clusters) > 0
  }

  # Team subnets
  # Extract subnet configurations from cluster definitions in all teams, preserving team association.
  # Keyed by derived cluster name ({team_key}-{location}).
  # Region is extracted from the location key by stripping the zone suffix (e.g., us-east1-b → us-east1).
  team_subnets = merge([
    for team_key, team in module.helpers.teams : {
      for location, cluster in team.google_kubernetes_engine_clusters != null ? team.google_kubernetes_engine_clusters : {} :
      "${team_key}-${location}" => merge(cluster.subnet, {
        region   = regex("^(us-[a-z]+-[0-9]+)-[a-z]$", location)[0]
        team_key = team_key
      })
    }
  ]...)

  # Teams with DNS Zones
  # Creates DNS zone configurations for teams with Kubernetes clusters.
  # Zone naming is env-first: prod → pneuma.osinfra.io, sb → pneuma.sb.osinfra.io, nonprod → pneuma.nonprod.osinfra.io.
  teams_with_dns_zones = {
    for team_key, team in module.helpers.teams :
    team_key => {
      dns_name = module.helpers.env == "prod" ? "${local.team_dns_subdomains[team_key]}.osinfra.io." : "${local.team_dns_subdomains[team_key]}.${module.helpers.env}.osinfra.io."
      name     = module.helpers.env == "prod" ? "${local.team_dns_subdomains[team_key]}-osinfra-io" : "${local.team_dns_subdomains[team_key]}-${module.helpers.env}-osinfra-io"
    }
    if team.google_kubernetes_engine_clusters != null && length(team.google_kubernetes_engine_clusters) > 0
  }

  # Teams with GKE Clusters
  # Identify teams that need Kubernetes projects
  teams_with_gke_clusters = {
    for team_key, team in module.helpers.teams :
    team_key => merge(team, {
      # Check if any cluster in this team has enable_gke_hub_host = true
      has_gke_hub_host = anytrue([
        for location, cluster in team.google_kubernetes_engine_clusters != null ? team.google_kubernetes_engine_clusters : {} :
        lookup(cluster, "enable_gke_hub_host", false)
      ])
    })
    if team.google_kubernetes_engine_clusters != null && length(team.google_kubernetes_engine_clusters) > 0
  }

  # Teams with GKE Hub Host
  # Subset of teams_with_gke_clusters where the team has a GKE Hub host cluster
  teams_with_gke_hub_host = {
    for team_key, team in local.teams_with_gke_clusters :
    team_key => team
    if team.has_gke_hub_host
  }

  # VPC Service Projects
  # Automatically include all Kubernetes projects as VPC service projects
  # Merges manually configured service projects with Kubernetes projects
  # Keys must be statically known at plan time, so team_key is used instead of project.id
  vpc_service_projects = merge(
    {
      for team_key, project in module.kubernetes_projects :
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

  # VPC Service Projects for Kubernetes
  # Only Kubernetes projects that need GKE-specific IAM permissions
  # Keys must be statically known at plan time, so team_key is used instead of project.id
  vpc_service_projects_kubernetes = {
    for team_key, project in module.kubernetes_projects :
    team_key => {
      id     = project.id
      number = project.number
    }
  }

  # Workload Identity
  # Configuration for external identity provider authentication

  # CEL ref assertions for the github-actions WIF provider (non-sandbox only).
  # Add entries here to permit additional refs (e.g. release tags).
  github_actions_ref_conditions = module.helpers.env == "sb" ? [] : [
    "assertion.ref == \"refs/heads/main\"",
    "assertion.ref.startsWith(\"refs/tags/\")",
  ]

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

      attribute_condition = module.helpers.env == "sb" ? "assertion.repository_owner_id==\"104685378\"" : "assertion.repository_owner_id==\"104685378\" && (${join(" || ", local.github_actions_ref_conditions)})"

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

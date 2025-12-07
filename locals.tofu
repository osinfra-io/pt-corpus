# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Billing users group - centrally managed in pt-logos, referenced here for membership management
  billing_users_group_name = module.helpers.teams["pt-logos"].billing_users_group.name

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
    ]) : "${item.team_key}-${item.repository}" => item
  }

  # Regional subnets
  # Organize subnets by region for regional deployments
  regional_subnets = local.team_subnets

  # Service Accounts
  # Create service accounts based on teams that have GitHub repositories
  service_accounts = {
    for team_key, team in module.helpers.teams :
    team_key => {
      github_repositories = team.github_repositories
    }
    if length(team.github_repositories) > 0
  }

  # Teams with GKE Clusters
  # Identify teams that need Kubernetes projects
  teams_with_gke_clusters = {
    for team_key, team in module.helpers.teams :
    team_key => merge(team, {
      # Check if any cluster in this team has enable_gke_hub_host = true
      has_gke_hub_host = anytrue([
        for cluster_key, cluster in lookup(team, "google_kubernetes_engine_clusters", {}) :
        lookup(cluster, "enable_gke_hub_host", false)
      ])
    })
    if length(lookup(team, "google_kubernetes_engine_clusters", {})) > 0
  }

  # VPC Service Projects
  # Automatically include all Kubernetes projects as VPC service projects
  # Merges manually configured service projects with Kubernetes projects
  vpc_service_projects = merge(
    var.vpc_service_projects,
    {
      for team_key, project in module.kubernetes_projects :
      project.id => {
        number = project.number
      }
    }
  )

  # VPC Service Projects for Kubernetes
  # Only Kubernetes projects that need GKE-specific IAM permissions
  vpc_service_projects_kubernetes = {
    for team_key, project in module.kubernetes_projects :
    project.id => {
      number = project.number
    }
  }

  # Team subnets
  # Aggregate subnet configurations from all teams in helpers module
  team_subnets = merge([
    for team_key, team in module.helpers.teams :
    lookup(team, "google_subnets", {})
  ]...)

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

      attribute_condition = module.helpers.env == "sb" ? "assertion.repository_owner_id==\"104685378\"" : "assertion.repository_owner_id==\"104685378\" && assertion.ref==\"refs/heads/main\""

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

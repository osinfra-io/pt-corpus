# Output Values
# https://opentofu.org/docs/language/values/outputs

output "kubernetes_projects" {
  description = "All Kubernetes projects created for each team with complete details"

  value = {
    for team_key, project in module.google_project_kubernetes :
    team_key => {
      environment = module.core_helpers.env
      id          = project.id
      number      = project.number
      team        = team_key
    }
  }
}

output "osinfra_io_dns_zone" {
  description = "The environment public DNS zone (osinfra.io in prod, sb.osinfra.io in sandbox, nonprod.osinfra.io in non-production)"
  value       = module.google_network_osinfra_io_dns
}

output "project_id" {
  description = "The project ID"
  value       = module.google_project.id
}

output "project_number" {
  description = "The project number"
  value       = module.google_project.number
}

output "regional_subnets" {
  description = "Regional subnets organized by region for consumption by regional deployments"
  value       = local.regional_subnets
}

output "service_accounts" {
  description = "Service accounts created for GitHub Actions"
  value = {
    for key, sa in google_service_account.github_actions :
    key => {
      email     = sa.email
      name      = sa.name
      unique_id = sa.unique_id
    }
  }
}

output "storage_buckets" {
  description = "Storage buckets created for OpenTofu state"
  value = {
    for key, bucket in module.google_storage_bucket :
    key => {
      name = bucket.name
      url  = bucket.url
    }
  }
}

output "teams" {
  description = "All teams data from logos workspaces with Kubernetes projects enriched"

  value = {
    for team_key, team in module.core_helpers.teams :
    team_key => merge(team, {
      google_projects = {
        for description, project in team.google_projects :
        description => {
          id       = module.google_project_teams["${team_key}-${description}"].id
          services = project.services
        }
        if contains(keys(module.google_project_teams), "${team_key}-${description}")
      }

      kubernetes_project = contains(keys(module.google_project_kubernetes), team_key) ? {
        environment = module.core_helpers.env
        id          = module.google_project_kubernetes[team_key].id
        number      = module.google_project_kubernetes[team_key].number
      } : null
    })
  }
}

output "vpc_name" {
  description = "The VPC name for regional deployments"
  value       = module.google_network_vpc.name
}

output "workload_identity_pools" {
  description = "Workload Identity Pools created for external authentication"
  value = {
    for key, pool in google_iam_workload_identity_pool.this :
    key => {
      name                      = pool.name
      workload_identity_pool_id = pool.workload_identity_pool_id
    }
  }
}

output "workload_identity_providers" {
  description = "Workload Identity Pool Providers created for OIDC authentication"
  value = {
    for key, provider in google_iam_workload_identity_pool_provider.this :
    key => {
      name                               = provider.name
      workload_identity_pool_provider_id = provider.workload_identity_pool_provider_id
    }
  }
}

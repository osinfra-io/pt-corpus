# Output Values
# https://opentofu.org/docs/language/values/outputs

output "platform_managed_projects" {
  description = "All platform-managed projects created for each team with complete details"

  value = {
    for team_key, project in module.google_project_platform_managed :
    team_key => {
      cloud_sql   = module.core_helpers.teams[team_key].platform_managed_project.cloud_sql
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
  description = "All teams data from logos workspaces with platform-managed projects enriched"

  value = {
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
}

output "vpc_name" {
  description = "The VPC name for regional deployments"
  value       = module.google_network_vpc.name
}

output "workload_identity_pools" {
  description = "Workload Identity Pools created for external authentication"
  value = {
    (google_iam_workload_identity_pool.this.workload_identity_pool_id) = {
      name                      = google_iam_workload_identity_pool.this.name
      workload_identity_pool_id = google_iam_workload_identity_pool.this.workload_identity_pool_id
    }
  }
}

output "workload_identity_providers" {
  description = "Workload Identity Pool Providers created for OIDC authentication"
  value = {
    (google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id) = {
      name                               = google_iam_workload_identity_pool_provider.this.name
      workload_identity_pool_provider_id = google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id
    }
  }
}

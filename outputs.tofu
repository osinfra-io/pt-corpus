# Output Values
# https://opentofu.org/docs/language/values/outputs

output "kubernetes_project_ids" {
  description = "The IDs of the Kubernetes projects"

  value = {
    for team_key, project in module.kubernetes_projects :
    team_key => project.id
  }
}

output "kubernetes_project_numbers" {
  description = "The numeric IDs of the Kubernetes projects"

  value = {
    for team_key, project in module.kubernetes_projects :
    team_key => project.number
  }
}

output "kubernetes_projects" {
  description = "All Kubernetes projects created for each team with complete details"

  value = {
    for team_key, project in module.kubernetes_projects :
    team_key => {
      id          = project.id
      name        = project.name
      number      = project.number
      project_id  = project.id
      team        = team_key
      environment = module.helpers.env
    }
  }
}

output "project_id" {
  description = "The project ID"
  value       = module.project.id
}

output "project_number" {
  description = "The project number"
  value       = module.project.number
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
    for key, bucket in module.state_storage_bucket :
    key => {
      name = bucket.name
      url  = bucket.url
    }
  }
}

output "teams" {
  description = "All teams data from logos workspaces"
  value       = module.helpers.teams
}

output "vpc_name" {
  description = "The VPC name for regional deployments"
  value       = var.enable_networking ? module.vpc[0].name : null
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

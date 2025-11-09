# Output Values
# https://opentofu.org/docs/language/values/outputs

output "project_id" {
  description = "The project ID"
  value       = module.project.id
}

output "project_number" {
  description = "The project number"
  value       = module.project.number
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

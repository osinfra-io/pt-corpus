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

output "teams" {
  description = "All teams data from logos workspaces"
  value       = module.helpers.teams
}

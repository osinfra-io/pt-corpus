# Output Values
# https://opentofu.org/docs/language/values/outputs

output "osinfra_io_dns_zone" {
  description = "The environment public DNS zone (osinfra.io in prod, sb.osinfra.io in sandbox, nonprod.osinfra.io in non-production)"
  value       = module.google_network_osinfra_io_dns
}

output "platform_managed_projects" {
  description = "All platform-managed projects created for each team with complete details"
  value       = local.output_platform_managed_projects
}

output "private_dns_zone" {
  description = "The environment private DNS zone, for regional deployments to create records against"
  value       = local.output_private_dns_zone
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
  value       = local.output_service_accounts
}

output "storage_buckets" {
  description = "Storage buckets created for OpenTofu state"
  value       = local.output_storage_buckets
}

output "teams" {
  description = "All teams data from logos workspaces with platform-managed projects enriched"
  value       = local.output_teams
}

output "vpc_name" {
  description = "The VPC name for regional deployments"
  value       = module.google_network_vpc.name
}

output "workload_identity_pools" {
  description = "Workload Identity Pools created for external authentication"
  value       = local.output_workload_identity_pools
}

output "workload_identity_providers" {
  description = "Workload Identity Pool Providers created for OIDC authentication"
  value       = local.output_workload_identity_providers
}

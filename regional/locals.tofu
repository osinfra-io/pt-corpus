# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Main workspace outputs
  main = data.terraform_remote_state.main.outputs

  # Regional subnets
  # Filter subnets for the current region from the main state
  regional_subnets = lookup(local.main.regional_subnets, module.core_helpers.region, {})

  # Cloud SQL instances in the current region
  # Flatten each platform-managed project's cloud_sql map (keyed by team-chosen instance name) into
  # one entry per instance that includes the current region, keyed by team_key-instance_key
  cloud_sql_instances_in_region = merge([
    for team_key, project in local.main.platform_managed_projects : {
      for instance_key, instance in project.cloud_sql :
      "${team_key}-${instance_key}" => {
        instance     = instance
        instance_key = instance_key
        project_id   = project.id
        team_key     = team_key
      }
      if contains(tolist(instance.regions), module.core_helpers.region)
    }
  ]...)
}

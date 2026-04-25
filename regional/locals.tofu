# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Main workspace outputs
  main = data.terraform_remote_state.main.outputs

  # Regional subnets
  # Filter subnets for the current region from the main state
  regional_subnets = lookup(local.main.regional_subnets, module.core_helpers.region, {})

  # Teams with Cloud SQL in the current region
  # Filter platform-managed projects that have Cloud SQL configured for the current deployment region
  teams_with_cloud_sql_in_region = {
    for team_key, project in local.main.platform_managed_projects :
    team_key => project
    if length(tolist(project.cloud_sql.regions)) > 0 &&
    contains(tolist(project.cloud_sql.regions), module.core_helpers.region)
  }
}

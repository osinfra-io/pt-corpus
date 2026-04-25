# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Main workspace outputs
  main = data.terraform_remote_state.main.outputs

  # Regional subnets
  # Filter subnets for the current region from the main state
  regional_subnets = lookup(local.main.regional_subnets, module.core_helpers.region, {})

  # Teams with Cloud SQL in the current region
  # Filter platform-managed teams that have Cloud SQL configured for the current deployment region
  teams_with_cloud_sql_in_region = {
    for team_key, team in module.core_helpers.teams :
    team_key => team
    if try(team.platform_managed_project.cloud_sql != null, false) &&
    contains(tolist(try(team.platform_managed_project.cloud_sql.regions, [])), module.core_helpers.region) &&
    contains(keys(local.main.platform_managed_projects), team_key)
  }
}

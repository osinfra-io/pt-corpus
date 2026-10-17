# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Cloud services service agent members
  cloud_services_members = {
    for k, v in local.regional_subnets : k => "serviceAccount:${v.service_project_number}@cloudservices.gserviceaccount.com"
  }

  # Cloud SQL deletion protection
  cloud_sql_deletion_protection = module.core_helpers.env == "prod"

  # Cloud SQL instances in the current region
  # Flatten each platform-managed project's cloud_sql map (keyed by team-chosen instance name) into
  # one entry per instance that includes the current region, keyed by team_key-instance_key
  cloud_sql_instances_in_region = merge([
    for team_key, project in local.main.platform_managed_projects : {
      for instance_key, instance in project.cloud_sql :
      "${team_key}-${instance_key}" => {
        dns_name     = "${instance_key}.${module.core_helpers.region}.sql.${team_key}.${local.main.private_dns_zone.dns_name}"
        instance     = instance
        instance_key = instance_key
        labels       = merge(module.core_helpers.labels, { team = team_key })
        project_id   = project.id
        team_key     = team_key
      }
      if contains(tolist(instance.regions), module.core_helpers.region)
    }
  ]...)

  # Container Engine robot members
  container_engine_members = {
    for k, v in local.regional_subnets : k => "serviceAccount:service-${v.service_project_number}@container-engine-robot.iam.gserviceaccount.com"
  }

  # Main workspace outputs
  main = data.terraform_remote_state.main.outputs

  # Main workspace name
  main_workspace = "main-${module.core_helpers.environment}"

  # Master subnet names
  master_subnet_names = {
    for k, v in local.regional_subnets : k => "${k}-master"
  }

  # Output values
  output_cloud_sql_instances = {
    for key, sql in module.google_cloud_sql :
    key => {
      host_fqdn          = trimsuffix(google_dns_record_set.cloud_sql[key].name, ".")
      instance           = sql.instance
      private_ip_address = sql.private_ip_address
    }
  }

  # Regional subnets
  # Filter subnets for the current region from the main state
  regional_subnets = lookup(local.main.regional_subnets, module.core_helpers.region, {})
}

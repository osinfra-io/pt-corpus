# Output Values
# https://opentofu.org/docs/language/values/outputs

output "cloud_sql_instances" {
  description = "Cloud SQL instances created for each team in this region"
  value = {
    for team_key, sql in module.google_cloud_sql :
    team_key => {
      host_fqdn          = trimsuffix(google_dns_record_set.cloud_sql[team_key].name, ".")
      instance           = sql.instance
      private_ip_address = sql.private_ip_address
    }
  }
}

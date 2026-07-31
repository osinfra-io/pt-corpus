# Output Values
# https://opentofu.org/docs/language/values/outputs

output "cloud_sql_instances" {
  description = "Cloud SQL instances created in this region, keyed by a jsonencode([team_key, instance_key]) tuple"
  value = {
    for key, sql in module.google_cloud_sql :
    key => {
      host_fqdn          = trimsuffix(google_dns_record_set.cloud_sql[key].name, ".")
      instance           = sql.instance
      private_ip_address = sql.private_ip_address
    }
  }
}

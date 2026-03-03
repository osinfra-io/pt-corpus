kubernetes_project_monthly_budget_amount = 5

# NS delegation records for sb.osinfra.io and nonprod.osinfra.io in the production osinfra.io zone.
# After sandbox and non-production are deployed, get nameservers from pt-corpus outputs:
#   tofu output env_osinfra_io_dns_zone
#
# public_dns_ns_delegations = [
#   {
#     managed_zone = "osinfra-io"
#     name         = "sb.osinfra.io"
#     ttl          = 300
#     rrdatas      = [] # nameservers from sandbox pt-corpus output: env_osinfra_io_dns_zone.name_servers
#   },
#   {
#     managed_zone = "osinfra-io"
#     name         = "nonprod.osinfra.io"
#     ttl          = 300
#     rrdatas      = [] # nameservers from non-production pt-corpus output: env_osinfra_io_dns_zone.name_servers
#   },
# ]

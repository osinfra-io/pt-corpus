kubernetes_project_monthly_budget_amount = 5

# NS delegation records for subdomain zones in the production public DNS zone.
# After sandbox and non-production are first deployed, get nameservers from pt-corpus outputs:
#   tofu output public_dns_zones
#
# public_dns_ns_delegations = [
#   {
#     managed_zone = "pneuma-osinfra-io"
#     name         = "sb.pneuma.osinfra.io"
#     ttl          = 300
#     rrdatas      = [] # nameservers from sandbox pt-corpus output: public_dns_zones["pt-pneuma"].name_servers
#   },
#   {
#     managed_zone = "pneuma-osinfra-io"
#     name         = "nonprod.pneuma.osinfra.io"
#     ttl          = 300
#     rrdatas      = [] # nameservers from non-production pt-corpus output: public_dns_zones["pt-pneuma"].name_servers
#   },
# ]

kubernetes_project_monthly_budget_amount = 5

osinfra_io_ns_delegations = [
  {
    managed_zone = "osinfra-io"
    name         = "sb.osinfra.io"
    ttl          = 300
    rrdatas = [
      "ns-cloud-e1.googledomains.com.",
      "ns-cloud-e2.googledomains.com.",
      "ns-cloud-e3.googledomains.com.",
      "ns-cloud-e4.googledomains.com.",
    ]
  },
  {
    managed_zone = "osinfra-io"
    name         = "nonprod.osinfra.io"
    ttl          = 300
    rrdatas = [
      "ns-cloud-b1.googledomains.com.",
      "ns-cloud-b2.googledomains.com.",
      "ns-cloud-b3.googledomains.com.",
      "ns-cloud-b4.googledomains.com.",
    ]
  },
]

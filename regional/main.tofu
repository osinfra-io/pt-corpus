# Google Subnet Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_subnets" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional?ref=68fb1e3db389fbeebde396ee61ba4ec3832123a7" # v0.3.5

  for_each                 = local.regional_subnets
  ip_cidr_range            = each.value.ip_cidr_range
  name                     = each.key
  network                  = local.main.vpc_name
  private_ip_google_access = true
  project                  = local.main.project_id

  secondary_ip_ranges = [
    {
      ip_cidr_range = each.value.pod_ip_cidr_range
      range_name    = "k8s-secondary-pods"
    },
    {
      ip_cidr_range = each.value.services_ip_cidr_range
      range_name    = "k8s-secondary-services"
    }
  ]
}

module "google_network_cloud_nat" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional/nat?ref=68fb1e3db389fbeebde396ee61ba4ec3832123a7" # v0.3.5

  depends_on = [
    module.google_network_subnets
  ]

  network = local.main.vpc_name
  project = local.main.project_id
}

# Compute Subnetwork IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_subnetwork_iam

resource "google_compute_subnetwork_iam_member" "cloud_services" {
  for_each = local.regional_subnets

  member     = "serviceAccount:${each.value.service_project_number}@cloudservices.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine" {
  for_each = local.regional_subnets

  member     = "serviceAccount:service-${each.value.service_project_number}@container-engine-robot.iam.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_subnets[each.key].name
}

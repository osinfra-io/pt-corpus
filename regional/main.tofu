# OpenTofu Remote State Datasource
# https://opentofu.org/docs/language/state/remote-state-data/

data "terraform_remote_state" "main" {
  backend = "gcs"

  config = {
    bucket             = var.remote_bucket
    kms_encryption_key = var.state_kms_encryption_key
    prefix             = "pt-corpus"
  }

  workspace = "main-${module.helpers.environment}"
}

# Google Cloud NAT Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-cloud-nat

module "cloud_nat" {
  source = "github.com/osinfra-io/opentofu-google-network//regional/nat?ref=v0.2.3"

  network = local.main.vpc_name
  project = local.main.project_id

  depends_on = [
    module.subnets
  ]
}

# Google Subnet Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-google-subnet

module "subnets" {
  for_each = local.regional_subnets
  source   = "github.com/osinfra-io/opentofu-google-network//regional?ref=v0.2.3"

  ip_cidr_range            = each.value.ip_cidr_range
  name                     = each.key
  network                  = local.main.vpc_name
  private_ip_google_access = true
  project                  = local.main.project_id

  secondary_ip_ranges = [
    {
      ip_cidr_range = each.value.services_ip_cidr_range
      range_name    = "k8s-secondary-services"
    },
    {
      ip_cidr_range = each.value.pod_ip_cidr_range
      range_name    = "k8s-secondary-pods"
    }
  ]
}

# Compute Subnetwork IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/compute_subnetwork_iam

resource "google_compute_subnetwork_iam_member" "cloud_services" {
  for_each = local.regional_subnets

  member     = "serviceAccount:${each.value.service_project_number}@cloudservices.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine" {
  for_each = local.regional_subnets

  member     = "serviceAccount:service-${each.value.service_project_number}@container-engine-robot.iam.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.subnets[each.key].name
}

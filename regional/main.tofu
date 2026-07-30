# Google Cloud SQL Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-cloud-sql

module "google_cloud_sql" {
  source = "github.com/osinfra-io/pt-arche-google-cloud-sql//regional?ref=a1325d4daffb3e5b7f18c48d9780509cc33d5aec" # v0.2.8

  for_each = local.cloud_sql_instances_in_region

  database_version    = each.value.instance.database_version
  deletion_protection = module.core_helpers.env == "prod"
  host_project_id     = local.main.project_id
  instance_name       = each.value.instance_key
  labels              = merge(module.core_helpers.labels, { team = each.value.team_key })
  machine_tier        = each.value.instance.machine_tier
  network             = local.main.vpc_name
  project             = each.value.project_id
  region              = module.core_helpers.region
}

# Google Subnet Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_master_subnets" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional?ref=a27322fd1ee0c4dc11cbfe34d3266a99ff8f075f" # v0.3.7

  for_each                 = local.regional_subnets
  ip_cidr_range            = each.value.master_ipv4_cidr_block
  name                     = "${each.key}-master"
  network                  = local.main.vpc_name
  private_ip_google_access = true
  project                  = local.main.project_id
}

module "google_network_subnets" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional?ref=a27322fd1ee0c4dc11cbfe34d3266a99ff8f075f" # v0.3.7

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
  source = "github.com/osinfra-io/pt-arche-google-network//regional/nat?ref=a27322fd1ee0c4dc11cbfe34d3266a99ff8f075f" # v0.3.7

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

resource "google_compute_subnetwork_iam_member" "cloud_services_master" {
  for_each = local.regional_subnets

  member     = "serviceAccount:${each.value.service_project_number}@cloudservices.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_master_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine" {
  for_each = local.regional_subnets

  member     = "serviceAccount:service-${each.value.service_project_number}@container-engine-robot.iam.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine_master" {
  for_each = local.regional_subnets

  member     = "serviceAccount:service-${each.value.service_project_number}@container-engine-robot.iam.gserviceaccount.com"
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_master_subnets[each.key].name
}

# DNS Record Set Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/dns_record_set

resource "google_dns_record_set" "cloud_sql" {
  for_each = local.cloud_sql_instances_in_region

  managed_zone = local.main.private_dns_zone.name
  name         = "${each.value.instance_key}.${module.core_helpers.region}.${each.value.team_key}.${local.main.private_dns_zone.dns_name}"
  project      = local.main.project_id
  rrdatas      = [module.google_cloud_sql[each.key].private_ip_address]
  ttl          = 300
  type         = "A"
}

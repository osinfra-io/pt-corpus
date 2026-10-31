# Google Cloud SQL Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-cloud-sql

module "google_cloud_sql" {
  source = "github.com/osinfra-io/pt-arche-google-cloud-sql//regional?ref=dd679a9b0270a4d4af50ad3ba0d39d46d1b7fa07" # v0.2.14

  for_each = local.cloud_sql_instances_in_region

  database_version    = each.value.instance.database_version
  deletion_protection = local.cloud_sql_deletion_protection
  host_project_id     = local.main.project_id
  instance_name       = each.value.instance_key
  labels              = each.value.labels
  machine_tier        = each.value.instance.machine_tier
  network             = local.main.vpc_name
  project             = each.value.project_id
  region              = module.core_helpers.region
}

# Google Subnet Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-google-network

module "google_network_master_subnets" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional?ref=924f2acc3087b3acc65c40435dc12e2572024c9d" # v0.3.13

  for_each                 = local.regional_subnets
  ip_cidr_range            = each.value.master_ipv4_cidr_block
  name                     = local.master_subnet_names[each.key]
  network                  = local.main.vpc_name
  private_ip_google_access = true
  project                  = local.main.project_id
}

module "google_network_subnets" {
  source = "github.com/osinfra-io/pt-arche-google-network//regional?ref=924f2acc3087b3acc65c40435dc12e2572024c9d" # v0.3.13

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
  source = "github.com/osinfra-io/pt-arche-google-network//regional/nat?ref=924f2acc3087b3acc65c40435dc12e2572024c9d" # v0.3.13

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

  member     = local.cloud_services_members[each.key]
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "cloud_services_master" {
  for_each = local.regional_subnets

  member     = local.cloud_services_members[each.key]
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_master_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine" {
  for_each = local.regional_subnets

  member     = local.container_engine_members[each.key]
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_subnets[each.key].name
}

resource "google_compute_subnetwork_iam_member" "container_engine_master" {
  for_each = local.regional_subnets

  member     = local.container_engine_members[each.key]
  project    = local.main.project_id
  region     = module.core_helpers.region
  role       = "roles/compute.networkUser"
  subnetwork = module.google_network_master_subnets[each.key].name
}

# DNS Record Set Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/dns_record_set

resource "google_dns_record_set" "cloud_sql" {
  for_each = local.cloud_sql_instances_in_region

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", each.value.instance_key))
      error_message = "Cloud SQL instance key ${each.value.instance_key} is used as a DNS label and must be a valid RFC 1035 label: lowercase letters, digits and hyphens, starting with a letter, not ending with a hyphen, and at most 63 characters."
    }
  }

  managed_zone = local.main.private_dns_zone.name
  name         = each.value.dns_name
  project      = local.main.project_id
  rrdatas      = [module.google_cloud_sql[each.key].private_ip_address]
  ttl          = 300
  type         = "A"
}

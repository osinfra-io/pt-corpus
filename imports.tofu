# Import Blocks
# https://opentofu.org/docs/language/import

import {
  for_each = toset(module.helpers.env == "prod" ? ["osinfra-io"] : [])
  id       = "projects/${module.project.id}/managedZones/${each.key}"
  to       = module.osinfra_io_dns[each.key].google_dns_managed_zone.this
}

import {
  id = "pt-pneuma-state-${module.helpers.env}"
  to = module.state_storage_bucket["pt-pneuma"].google_storage_bucket.this
}

import {
  for_each = local.teams_with_dns_zones
  id       = "projects/${module.project.id}/managedZones/${each.value.name}"
  to       = module.public_dns[each.key].google_dns_managed_zone.this
}

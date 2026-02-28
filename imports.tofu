# Import Blocks
# https://opentofu.org/docs/language/import

import {
  for_each = toset(module.helpers.env == "prod" ? ["osinfra-io"] : [])
  id       = "projects/${module.project.id}/managedZones/${each.key}"
  to       = module.osinfra_io_dns[each.key].google_dns_managed_zone.this
}

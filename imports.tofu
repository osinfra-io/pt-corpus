# Import Blocks
# https://opentofu.org/docs/language/import

import {
  id = "projects/${module.project.id}/managedZones/osinfra-io"
  to = module.osinfra_io_dns[0].google_dns_managed_zone.this
}

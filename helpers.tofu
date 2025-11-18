# OpenTofu Core Helpers Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-core-helpers

module "helpers" {
  source = "github.com/osinfra-io/opentofu-core-helpers//root?ref=refactor"

  cost_center         = "x001"
  data_classification = "public"

  # Logos functionality - consolidated into core-helpers
  logos_workspaces = ["pt-corpus-main-production", "pt-logos-main-production"]

  repository               = "pt-corpus"
  state_kms_encryption_key = "projects/pt-corpus-tf16-prod/locations/us/keyRings/state-encryption/cryptoKeys/default"
  team                     = "pt-corpus"
}

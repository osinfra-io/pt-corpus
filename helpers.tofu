# OpenTofu Core Helpers Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-core-helpers

module "core_helpers" {
  source = "github.com/osinfra-io/pt-arche-core-helpers//root?ref=9734175404f3c0b26b0a58a6c877828dba2dea70" # v0.2.1

  cost_center         = "x001"
  data_classification = "public"

  # Logos functionality - consolidated into core-helpers
  logos_workspaces = [
    "pt-arche-main-production",
    "pt-corpus-main-production",
    "pt-ekklesia-main-production",
    "pt-logos-main-production",
    "pt-pneuma-main-production",
    "pt-techne-main-production"
  ]

  repository = "pt-corpus"
  team       = "pt-corpus"
}

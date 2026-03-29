# OpenTofu Core Helpers Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-core-helpers

module "core_helpers" {
  source = "github.com/osinfra-io/pt-arche-core-helpers//root?ref=37126d7c6b48b027fc57272c7e58c49e8c3753ff" # v0.2.2

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

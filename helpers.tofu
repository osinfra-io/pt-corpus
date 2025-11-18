# OpenTofu Core Helpers Module (osinfra.io)
# https://github.com/osinfra-io/opentofu-core-helpers

module "helpers" {
  source = "github.com/osinfra-io/opentofu-core-helpers//root?ref=refactor"

  cost_center         = "x001"
  data_classification = "public"

  # Logos functionality - consolidated into core-helpers
  logos_workspaces = ["pt-Zcorpus-main-production", "pt-logos-main-production"]

  repository = "pt-corpus"
  team       = "pt-corpus"
}

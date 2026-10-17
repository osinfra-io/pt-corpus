# OpenTofu Remote State Datasource
# https://opentofu.org/docs/language/state/remote-state-data/

data "terraform_remote_state" "main" {
  backend = "gcs"

  config = {
    bucket = var.remote_bucket
    prefix = "pt-corpus"
  }

  workspace = local.main_workspace
}

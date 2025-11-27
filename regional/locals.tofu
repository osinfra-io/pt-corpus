# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Main workspace outputs
  main = data.terraform_remote_state.main.outputs

  # Regional subnets
  # Filter subnets for the current region from the main state
  regional_subnets = lookup(local.main.regional_subnets, module.helpers.region, {})
}

# Moved Blocks
# https://opentofu.org/docs/language/moved

moved {
  from = module.cloud_nat
  to   = module.google_network_cloud_nat
}

moved {
  from = module.helpers
  to   = module.core_helpers
}

moved {
  from = module.subnets
  to   = module.google_network_subnets
}

# Moved Blocks
# https://opentofu.org/docs/language/moved

moved {
  from = module.public_dns[0]
  to   = module.public_dns["pt-pneuma"]
}

# Input Variables
# https://opentofu.org/docs/language/values/variables

variable "remote_bucket" {
  description = "The remote bucket the `terraform_remote_state` data source retrieves the state from"
  type        = string
}

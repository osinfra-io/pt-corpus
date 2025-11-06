# Data Sources
# https://opentofu.org/docs/language/data-sources

# Local File Data Source for Logos Team Outputs
# https://search.opentofu.org/provider/hashicorp/local/latest/docs/data-sources/file

data "local_file" "logos_outputs" {
  filename = "${path.module}/outputs.txt"
}

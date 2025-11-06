# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Parse logos outputs from the data source using regex extraction
  # Note: This will eventually be replaced with terraform_remote_state data source
  outputs_content = data.local_file.logos_outputs.content

  # Extract all environment folders from logos outputs
  sandbox_folder_id        = regex("\"Sandbox\" = \"(folders/[0-9]+)\"", local.outputs_content)[0]
  non_production_folder_id = regex("\"Non-Production\" = \"(folders/[0-9]+)\"", local.outputs_content)[0]
  production_folder_id     = regex("\"Production\" = \"(folders/[0-9]+)\"", local.outputs_content)[0]

  # Extract team folder ID
  corpus_team_folder_id = regex("\"team_folder_id\" = \"(folders/[0-9]+)\"", local.outputs_content)[0]

  # Extract repository name
  repository_name = regex("\"name\" = \"([^\"]+)\"", local.outputs_content)[0]

  # Extract team name from logos outputs
  # The outputs contain the team key which is the team name
  # From outputs: "corpus" = { ... } -> team_name = "corpus"
  team_name = regex("\"([^\"]+)\" = \\{", local.outputs_content)[0]

  # Dynamically determine environment folder based on workspace name
  # Expected workspace patterns: sandbox-main, non-production-main, production-main
  workspace_environment = split("-", terraform.workspace)[0]

  # Map workspace environment to folder ID
  environment_folder_id = local.workspace_environment == "sandbox" ? local.sandbox_folder_id : (
    local.workspace_environment == "non-production" ? local.non_production_folder_id : (
      local.workspace_environment == "production" ? local.production_folder_id : local.sandbox_folder_id
    )
  )

  # GitHub repositories for service account mapping
  github_repositories = {
    "plt-lz-${local.repository_name}" = {
      name       = "plt-lz-${local.repository_name}"
      repository = local.repository_name
    }
  }

  # Service accounts based on GitHub repositories
  service_accounts = toset(keys(local.github_repositories))
}

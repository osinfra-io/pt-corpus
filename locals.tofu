# Local Values
# https://opentofu.org/docs/language/values/locals

locals {

  # GitHub Repositories
  # Create a map of repositories for workload identity bindings
  github_repositories = {
    for item in flatten([
      for team_key, team in module.helpers.teams : [
        for repo_key, repo in team.github_repositories : {
          name       = team_key
          repository = repo_key
          team_key   = team_key
        }
      ]
    ]) : "${item.team_key}-${item.repository}" => item
  }

  # Service Accounts
  # Create service accounts based on teams that have GitHub repositories
  service_accounts = {
    for team_key, team in module.helpers.teams :
    team_key => {
      github_repositories = team.github_repositories
    }
    if length(team.github_repositories) > 0
  }
}

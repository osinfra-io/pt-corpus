# Moved Blocks
# https://opentofu.org/docs/language/moved

# Rename github_repositories map keys: drop redundant team_key prefix.
# The repo keys from pt-logos already include the team prefix, so the old
# "${team_key}-${repo_key}" construction was duplicating it. These blocks
# can be removed once all environments have been applied.

moved {
  from = google_service_account_iam_member.github_actions["pt-corpus-pt-corpus"]
  to   = google_service_account_iam_member.github_actions["pt-corpus"]
}

moved {
  from = google_service_account_iam_member.github_actions["pt-logos-pt-logos"]
  to   = google_service_account_iam_member.github_actions["pt-logos"]
}

moved {
  from = google_service_account_iam_member.github_actions["pt-pneuma-pt-pneuma"]
  to   = google_service_account_iam_member.github_actions["pt-pneuma"]
}

moved {
  from = google_service_account_iam_member.github_actions["pt-pneuma-pt-pneuma-istio-test"]
  to   = google_service_account_iam_member.github_actions["pt-pneuma-istio-test"]
}

moved {
  from = module.datadog
  to   = module.datadog_google_integration
}

moved {
  from = module.google_project_datadog
  to   = module.datadog_google_integration_datadog_projects
}

moved {
  from = module.helpers
  to   = module.core_helpers
}

moved {
  from = module.kubernetes_datadog
  to   = module.datadog_google_integration_kubernetes_projects
}

moved {
  from = module.kubernetes_projects
  to   = module.google_project_kubernetes
}

moved {
  from = module.osinfra_io_dns
  to   = module.google_network_osinfra_io_dns
}

moved {
  from = module.private_dns
  to   = module.google_network_private_dns
}

moved {
  from = module.project
  to   = module.google_project
}

moved {
  from = module.state_storage_bucket
  to   = module.google_storage_bucket
}

moved {
  from = module.team_dns
  to   = module.google_network_team_dns
}

moved {
  from = module.vpc
  to   = module.google_network_vpc
}

moved {
  from = google_artifact_registry_repository.docker_standard
  to   = google_artifact_registry_repository.docker_standards
}

moved {
  from = google_artifact_registry_repository.docker_virtual
  to   = google_artifact_registry_repository.docker_virtuals
}

moved {
  from = google_dns_record_set.osinfra_io_ns_delegation
  to   = google_dns_record_set.osinfra_io_ns_delegations
}

moved {
  from = google_dns_record_set.team_ns_delegation
  to   = google_dns_record_set.team_ns_delegations
}

moved {
  from = google_project_iam_member.multi_cluster_service_agent
  to   = google_project_iam_member.multi_cluster_service_agents
}

moved {
  from = google_project_service_identity.multi_cluster_service_agent
  to   = google_project_service_identity.multi_cluster_service_agents
}

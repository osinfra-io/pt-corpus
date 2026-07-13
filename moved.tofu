# Moved Blocks
# https://opentofu.org/docs/language/moved

moved {
  from = google_iam_workload_identity_pool.this["github-actions"]
  to   = google_iam_workload_identity_pool.this
}

moved {
  from = google_iam_workload_identity_pool_provider.this["github-actions"]
  to   = google_iam_workload_identity_pool_provider.this
}

moved {
  from = module.google_projects
  to   = module.google_project_teams
}

moved {
  from = module.google_project_kubernetes
  to   = module.google_project_platform_managed
}

moved {
  from = module.datadog_google_integration_kubernetes_projects
  to   = module.datadog_google_integration_platform_managed_projects
}

moved {
  from = google_project_iam_member.kubernetes_project_owners
  to   = google_project_iam_member.platform_managed_project_owners
}

moved {
  from = google_project_iam_member.kubernetes_project_pneuma_owners
  to   = google_project_iam_member.platform_managed_project_pneuma_owners
}

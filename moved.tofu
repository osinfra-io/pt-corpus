# Moved Blocks
# https://opentofu.org/docs/language/moved

# Resources previously keyed by project.id (a computed value) are re-keyed by
# team_key (a static value) so for_each map keys are known at plan time.

moved {
  from = google_compute_shared_vpc_service_project.this["pt-pneuma-k8s-tf11-sb"]
  to   = google_compute_shared_vpc_service_project.this["pt-pneuma"]
}

moved {
  from = google_project_iam_member.container_engine_firewall_management["pt-pneuma-k8s-tf11-sb"]
  to   = google_project_iam_member.container_engine_firewall_management["pt-pneuma"]
}

moved {
  from = google_project_iam_member.container_engine_service_agent_user["pt-pneuma-k8s-tf11-sb"]
  to   = google_project_iam_member.container_engine_service_agent_user["pt-pneuma"]
}

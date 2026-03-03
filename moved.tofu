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

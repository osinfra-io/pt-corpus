# Corpus Team Instructions

## GitHub Actions

Corpus uses a three-tier deployment workflow:

- **`sandbox.yml`** — runs on pull requests; deploys to sandbox via `osinfra-io/pt-techne-opentofu-workflows`
- **`non-production.yml`** — runs on merge to `main`; deploys to non-production
- **`production.yml`** — runs automatically after non-production succeeds

The main workspace and `regional/` workspace each have their own workflow jobs and deploy independently. Regional jobs run after the main workspace completes.

When modifying workflows, update the Mermaid diagram in `README.md` to reflect the changes.

## Repository Practices

- Local development does not have access to OpenTofu state — plans and applies run exclusively in GitHub Actions.
- The `shared/` directory contains canonical backend and provider configurations symlinked into every workspace directory. When adding new workspace directories, symlink from `shared/`.
- For detailed OpenTofu conventions (file structure, module pinning, resource patterns, workspace naming), refer to `.github/skills/opentofu.md`.

# pt-corpus Repository - Copilot Agent Onboarding Guide

## Repository Summary
**Type**: Infrastructure as Code (OpenTofu/Terraform)
**Purpose**: Team-specific infrastructure layer creating Google Cloud projects, Datadog integrations, GitHub Actions infrastructure, and state management while consuming foundational platform data from pt-logos
**Size**: ~10 files, ~300 lines of OpenTofu configuration
**Language**: HCL (HashiCorp Configuration Language)
**Runtime**: OpenTofu v1.10.7+
**Providers**: Google Cloud (v7.9.0), Datadog (v3.78.0)

## Critical Build & Validation Commands

**ALWAYS run these commands in this exact order before committing:**

```bash
# 1. Install pre-commit hooks (first time only)
pre-commit install

# 2. Run all validation checks (REQUIRED before every commit)
cd /home/brett/Repositories/osinfra-io/pt-corpus
pre-commit run -a
```

**Expected output**: All hooks should pass with "Passed" status. The hooks run:
- `check-yaml` - Validates YAML syntax
- `end-of-file-fixer` - Ensures files end with newline
- `trailing-whitespace` - Removes trailing whitespace
- `check-symlinks` - Validates symbolic links
- `tofu-fmt` - Formats OpenTofu files (auto-fixes)
- `tofu-validate` - Validates OpenTofu configuration

**Common Issues**:
- If `tofu-validate` fails with "Error: No valid credential sources found", this is expected for local development without GCP credentials. The CI/CD pipeline has proper credentials.
- If `tofu-fmt` fails, it will auto-fix formatting. Run `pre-commit run -a` again to verify.

**Plugin Cache Optimization** (speeds up local validation):
```bash
mkdir -p $HOME/.opentofu.d/plugin-cache
export TF_PLUGIN_CACHE_DIR=$HOME/.opentofu.d/plugin-cache
```

## Repository Structure

**Core OpenTofu Files** (root directory):
- `main.tofu` - Module declarations and resource definitions
- `helpers.tofu` - Core helpers module configuration (logos integration)
- `locals.tofu` - Data transformations and local value definitions
- `variables.tofu` - Input variables with defaults (alphabetically ordered)
- `outputs.tofu` - Output values (alphabetically ordered)
- `providers.tofu` - Provider configurations (Google, Datadog)
- `backend.tofu` - GCS backend with KMS encryption

**Configuration & Environments**:
- `environments/*.tfvars` - Per-environment configuration files
  - `sandbox.tfvars` - Sandbox environment
  - `non-production.tfvars` - Non-production environment
  - `production.tfvars` - Production environment

**CI/CD & Automation**:
- `.github/workflows/sandbox.yml` - Sandbox environment deployment
- `.github/workflows/non-production.yml` - Non-production environment deployment
- `.github/workflows/production.yml` - Production environment deployment (triggered after non-prod success)
- `.github/workflows/dependabot.yml` - Dependency updates
- `.pre-commit-config.yaml` - Pre-commit hook configuration

**Documentation**:
- `README.md` - Comprehensive project documentation
- `.github/copilot-instructions.md` - This file

## Architecture Overview

**Resources Created**:
- **Google Cloud Project**: With CIS compliance, budget controls, and required APIs
- **Datadog Integration**: Cloud Security Posture Management (CSPM) and Security Command Center
- **GitHub Actions Infrastructure**: Service accounts, workload identity pools/providers, and repository-specific bindings
- **State Storage**: Encrypted GCS buckets (one per team with GitHub repositories) and KMS keys
- **Access Controls**: Team-based service accounts with billing group membership

**Critical Module Pattern**:
- `module.helpers` (opentofu-core-helpers): Fetches team data from pt-logos workspaces
  - Provides: labels, project naming, environment detection, team folder hierarchy, identity groups
  - Configuration: `logos_workspaces = ["pt-corpus-main-production", "pt-logos-main-production"]`

**Workspaces**:
- `main-sandbox` - Sandbox environment workspace
- `main-non-production` - Non-production environment workspace
- `main-production` - Production environment workspace

## Code Standards (CRITICAL)

### File Structure
- **All configuration files**: Variables, outputs, locals, and tfvars MUST be in strict alphabetical order
- **main.tofu structure**: Modules first, then resources alphabetically by resource type
- **Universal alphabetical ordering**: ALL arguments, keys, and properties at EVERY level of configuration must be alphabetically ordered (applies to variables, outputs, locals, resources, data sources, and nested blocks)

### Alphabetical Ordering with Logical Grouping Exception
Limited exception to strict alphabetical ordering allowed for service-specific configuration groups:

1. **Service configuration groups**: Variables or settings that configure the same service or resource type (e.g., Datadog credentials, Google Cloud settings, project configurations)
2. **Grouping requirement**: Must be annotated with a grouping comment explaining the logical relationship
3. **Alphabetical within groups**: Alphabetical ordering still applies within each grouped block
4. **Rationale**: Multi-service configurations benefit from grouping related settings together for clarity and maintainability

**Example of valid logical grouping**:
```hcl
# Datadog configuration (grouped by purpose)
datadog_api_key = "..."
datadog_app_key = "..."
datadog_enable = true

# Google Cloud configuration (grouped by purpose)
google_customer_id = "..."

# Project configuration (grouped by purpose)
project_billing_account = "..."
project_monthly_budget_amount = 5
```

### Meta-Arguments Priority
Meta-arguments (`for_each`, `count`, `depends_on`, `lifecycle`, `provider`) MUST be the first arguments in resources/data sources when required:

- **Position**: Always first, before all regular resource configuration arguments
- **Multiple meta-arguments**: Ordered alphabetically among themselves
- **lifecycle blocks**: Are meta-arguments and must be positioned before all regular resource configuration arguments
- **Nested block ordering**: Within nested blocks (lifecycle, provisioner, etc.), use normal alphabetical ordering

**Example**:
```hcl
resource "google_service_account" "github_actions" {
  for_each = local.service_accounts

  account_id   = "${each.key}-github"
  display_name = "Service account for GitHub Actions"
  project      = module.project.id
}
```

### Resource Arguments
- **All remaining arguments**: Must be in strict alphabetical order after meta-arguments, regardless of whether they're required or optional
- **No exceptions**: Alphabetical ordering applies to all standard resource arguments

### Formatting Rules
- **List/Map formatting**: Always have an empty newline before any list, map, or logic block unless it's the first argument. Always have an empty newline after any list, map, or logic block unless it's the last argument.
- **Function formatting**: Use single-line formatting for simple function calls. For complex functions with long lines or multiple arguments, break into multiple lines for readability. Prioritize readability over strict single-line requirements.

**Function formatting examples**:
```hcl
# Simple function - single line
name = "${each.key}-state-${module.helpers.env}"

# Complex function - multiple lines for readability
attribute_condition = module.helpers.env == "sb" ?
  "assertion.repository_owner_id==\"104685378\"" :
  "assertion.repository_owner_id==\"104685378\" && assertion.ref==\"refs/heads/main\""
```

## Helpers Module Pattern (CRITICAL)

The `helpers.tofu` file configures the opentofu-core-helpers module which provides foundational platform integration:

```hcl
module "helpers" {
  source = "github.com/osinfra-io/opentofu-core-helpers//root?ref=<version>"

  cost_center         = "x001"
  data_classification = "public"
  logos_workspaces    = ["pt-corpus-main-production", "pt-logos-main-production"]
  repository          = "pt-corpus"
  team                = "pt-corpus"
}
```

**Provides**:
- `module.helpers.labels` - Consistent labels for all resources
- `module.helpers.env` - Environment detection (sb/np/prod)
- `module.helpers.project_naming` - Standardized project names and descriptions
- `module.helpers.environment_folder_id` - Folder ID from pt-logos hierarchy
- `module.helpers.teams` - All team data (folders, identity groups, GitHub repos)

**NEVER modify** the helpers module configuration without understanding the pt-logos foundational platform.

## Locals Transformation Patterns

`locals.tofu` transforms helpers module data into consumable formats:

**Key Patterns**:
- `billing_users_group_name` - References centrally-managed billing group from pt-logos
- `github_repositories` - Flattens team GitHub repositories for workload identity bindings
- `service_accounts` - Creates service accounts only for teams with GitHub repositories
- `workload_identity` - Configures GitHub Actions OIDC with organization ID validation

**Example**:
```hcl
service_accounts = {
  for team_key, team in module.helpers.teams :
  team_key => {
    github_repositories = team.github_repositories
  }
  if length(team.github_repositories) > 0
}
```

## Multi-Environment Workflow

**Environment Progression**:
1. Sandbox → 2. Non-Production → 3. Production

**Workflows**:
- `sandbox.yml` - Deploys on push to main (manual or PR merge)
- `non-production.yml` - Deploys after sandbox completes successfully
- `production.yml` - Deploys after non-production completes successfully

**Workspace Pattern**:
- Workspace: `main-{environment}` (e.g., `main-sandbox`, `main-production`)
- Backend: GCS bucket per environment with KMS encryption
- Service Account: `pt-corpus-github@pt-corpus-tf16-prod.iam.gserviceaccount.com`

## Adding New Resources

1. Add module or resource to `main.tofu` (alphabetically by type)
2. Add required variables to `variables.tofu` (alphabetically ordered)
3. Add outputs to `outputs.tofu` if needed (alphabetically ordered)
4. Update environment-specific values in `environments/*.tfvars` as needed
5. Run `pre-commit run -a` to validate
6. Commit to main branch
7. GitHub Actions automatically deploys through environments (sandbox → non-prod → prod)

## Module Integration Pattern

This repository uses external modules for common functionality:

**Modules Used**:
- `opentofu-google-project` - Google Cloud project creation with CIS compliance
- `opentofu-datadog-google-integration` - Datadog integration with CSPM
- `opentofu-google-storage-bucket` - Encrypted GCS bucket creation
- `opentofu-core-helpers` - Logos platform integration

**Module References**:
- Always use pinned versions with git ref (e.g., `?ref=<commit_sha>`)
- Document version in comment (e.g., `# v0.4.7`)
- Module outputs are accessed via `module.<name>.<output>`

## CI/CD Pipeline

**Workflow Triggers**:
- Sandbox: Push to `main` branch (ignores `**.md` changes)
- Non-Production: After sandbox workflow completes successfully
- Production: After non-production workflow completes successfully

**Backend Configuration**:
- Sandbox: `pt-corpus-state-sb` bucket
- Non-Production: `pt-corpus-state-np` bucket
- Production: `pt-corpus-state-prod` bucket

**Service Account**: `pt-corpus-github@pt-corpus-tf16-prod.iam.gserviceaccount.com`

## Key Guidelines

✅ **Do**:
- Follow alphabetical ordering rigorously
- Use `pre-commit run -a` before every commit
- Preserve helpers module integration pattern
- Use module outputs rather than hardcoding values
- Test changes in sandbox first
- Document module versions with comments

❌ **Don't**:
- Modify helpers module configuration without understanding pt-logos
- Hardcode values that come from modules
- Skip environment progression (sandbox → non-prod → prod)
- Remove lifecycle protection from KMS resources (commented out for testing only)
- Use email addresses directly as resource keys

## Trust These Instructions

These instructions have been validated against the current codebase. Only perform additional searches if information is incomplete or found to be in error. The pre-commit hooks will catch most errors automatically.

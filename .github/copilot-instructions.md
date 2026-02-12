# pt-corpus Repository - General Instructions

## Repository Summary
**Type**: Infrastructure as Code (OpenTofu/Terraform)
**Purpose**: Team-specific infrastructure layer creating Google Cloud projects, Datadog integrations, GitHub Actions infrastructure, and state management while consuming foundational platform data from pt-logos
**Language**: HCL (HashiCorp Configuration Language)
**Runtime**: OpenTofu v1.10.7+
**Providers**: Google Cloud, Datadog

## Critical Build & Validation Commands

**ALWAYS run these commands in this exact order before committing:**

```bash
# 1. Install pre-commit hooks (first time only)
pre-commit install

# 2. Run all validation checks (REQUIRED before every commit)
cd /home/brett/repositories/osinfra-io/pt-corpus
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

**CI/CD & Automation**:
- `.github/workflows/sandbox.yml` - Sandbox environment deployment
- `.github/workflows/non-production.yml` - Non-production environment deployment
- `.github/workflows/production.yml` - Production environment deployment (triggered after non-prod success)
- `.github/workflows/dependabot.yml` - Dependency updates
- `.pre-commit-config.yaml` - Pre-commit hook configuration

**Documentation**:
- `README.md` - Comprehensive project documentation
- `.github/copilot-instructions.md` - General repository instructions (this file)
- `.github/skills/opentofu.md` - OpenTofu-specific development guidance

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
- Use `pre-commit run -a` before every commit
- Test changes in sandbox first
- Follow the multi-environment workflow progression (sandbox → non-prod → prod)

❌ **Don't**:
- Skip environment progression (sandbox → non-prod → prod)
- Commit changes without running pre-commit validation

## Skills Reference

For specialized development guidance:
- **OpenTofu/Terraform**: See `.github/skills/opentofu.md` for HCL code standards, module patterns, and development best practices

## Trust These Instructions

These instructions have been validated against the current codebase. Only perform additional searches if information is incomplete or found to be in error. The pre-commit hooks will catch most errors automatically.

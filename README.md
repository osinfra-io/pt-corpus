# Corpus

[![Dependabot](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-corpus/dependabot.yml?style=for-the-badge&logo=github&color=2088FF&label=Dependabot)](https://github.com/osinfra-io/pt-corpus/actions/workflows/dependabot.yml) [![Datadog Security Enabled](https://img.shields.io/badge/Datadog%20Security-Enabled-632CA6?style=for-the-badge&logo=datadog)](https://app.datadoghq.com/security/code-security/repositories?repository_id=pt-corpus)

## 📄 Repository Description

This repository contains the Infrastructure as Code (IaC) that shapes the Corpus domain — the embodied layer of the platform where order takes form. In the wider hierarchy of the Platform Team, Corpus serves as the stratum where the abstract principles of Logos are translated into tangible, reliable infrastructure.

Here, Google Cloud projects are called into being according to shared patterns; CIS-aligned safeguards establish the boundaries that keep chaos at bay; and Datadog observability forms the eyes of attention through which the system perceives and regulates itself.

The Corpus layer is where structure becomes real, where governance becomes flesh, and where the platform’s foundational energies are harnessed so teams can build, act, and create within a world made stable enough for meaningful work.

The infrastructure automates the creation of:

- **Google Cloud Project** with CIS compliance features, budget controls, and required APIs
- **Shared VPC** with service networking connection and peering ranges for GKE pods and services
- **Private and Public DNS Zones** with configurable record sets per team
- **Subnets** with GKE secondary ranges (pods and services) deployed per region
- **Cloud NAT** for outbound internet access in each regional deployment
- **Artifact Registry** with remote (Docker Hub proxy), standard, and virtual Docker repositories per team, with IAM bindings for image readers and writers
- **Kubernetes Projects** (one per team with GKE clusters) with Datadog integration — GKE clusters are created by pt-pneuma
- **Datadog Integration** with Cloud Security Posture Management (CSPM) and Security Command Center
- **Team Infrastructure** using the logos foundational platform for consistent labeling and governance
- **GitHub Actions Integration** with service accounts, workload identity, and state storage buckets
- **KMS Encryption** for secure state file encryption and key management
- **Group Memberships** for billing users and browser groups at the organizational level
- **Multi-environment Support** with sandbox, non-production, and production configurations

This establishes team-specific infrastructure while maintaining consistency with organizational standards and foundational platform practices.

## 🏭 Platform Information

- Documentation: [docs.osinfra.io](https://docs.osinfra.io/product-guides/google-cloud-platform/corpus)
- Service Interfaces: [github.com](https://github.com/osinfra-io/pt-corpus/issues/new/choose)

## <img align="left" width="35" height="35" src="https://github.com/user-attachments/assets/eb98a3be-2ffe-4c05-91a4-072fe795a167"> Development

Our focus is on the core fundamental practice of platform engineering, Infrastructure as Code.

>Open Source Infrastructure (as Code) is a development model for infrastructure that focuses on open collaboration and applying relative lessons learned from software development practices that organizations can use internally at scale. - [Open Source Infrastructure (as Code)](https://www.osinfra.io)

To avoid slowing down stream-aligned teams, we want to open up the possibility for contributions. The Open Source Infrastructure (as Code) model allows team members external to the platform team to contribute with only a slight increase in cognitive load. This section is for developers who want to contribute to this repository, describing the tools used, the skills, and the knowledge required, along with OpenTofu documentation.

See the [documentation](https://docs.osinfra.io/fundamentals/development-setup) for setting up a development environment.

### 🛠️ Tools

- [pre-commit](https://github.com/pre-commit/pre-commit)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pt-techne-pre-commit-hooks)

### 📋 Skills and Knowledge

Links to documentation and other resources required to develop and iterate in this repository successfully.

- [datadog cloud security posture management](https://docs.datadoghq.com/security/cloud_security_management/)
- [datadog google cloud integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)
- [google cloud platform cis benchmarks](https://cloud.google.com/security-command-center/docs/cis-benchmarks)
- [google cloud platform iam](https://cloud.google.com/iam/docs/overview)
- [google cloud platform kms](https://cloud.google.com/kms/docs)
- [google cloud platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [google cloud platform vpc networking](https://cloud.google.com/vpc/docs)
- [google kubernetes engine](https://cloud.google.com/kubernetes-engine/docs)

## Architecture

The infrastructure creates:

- **Google Cloud Project** with standardized naming, CIS compliance logging, budget controls, and required APIs
- **Shared VPC** with service networking connections and peering address ranges (172.16.0.0/16) for GKE
- **Private and Public DNS Zones** with automatic team zone delegation per environment
- **Subnets** with GKE primary and secondary IP ranges deployed per region (us-east1, us-east4)
- **Cloud NAT** for outbound connectivity in each regional deployment
- **Artifact Registry** with remote (Docker Hub proxy), standard, and virtual Docker repositories per team, with IAM bindings for image readers and writers
- **Kubernetes Projects** (one per team with GKE clusters) consuming Datadog integration — GKE clusters are created by pt-pneuma
- **Shared VPC Service Project Attachments** linking Kubernetes projects to the host VPC
- **Datadog Integration** with Cloud Security Posture Management (CSPM) and Security Command Center integration
- **Team Infrastructure** leveraging logos foundational platform for consistent labeling, environment detection, and governance
- **GitHub Actions Infrastructure** including service accounts, workload identity pools, and secure authentication
- **State Storage** with encrypted GCS buckets and KMS keys for secure OpenTofu state management
- **Access Controls** with team-based service accounts and repository-specific workload identity bindings
- **Multi-environment Support** with configurations for sandbox, non-production, and production deployments

## GitHub Actions Workflow

**Workflow Details:**

- **Three Workflows**: Sandbox, Non-Production, Production (identical job structure)
- **Triggers**:
  - Sandbox: Pull request (opened, synchronize), excluding .md files; manual dispatch
  - Non-Production: Push to main, excluding .md files; manual dispatch
  - Production: Triggered when Non-Production workflow completes successfully; manual dispatch
- **Job Dependencies**: Regional jobs (us-east1, us-east4) run in parallel after main job completion
- **Called Workflow**: [osinfra-io/pt-techne-opentofu-workflows](https://github.com/osinfra-io/pt-techne-opentofu-workflows) (v0.2.9)
- **Working Directory**: Main job uses root, regional jobs use `regional/` directory
- **Workspaces**: `main-[env]`, `us-east1-[env]`, `us-east4-[env]`

## Interface

### Environment-Specific Configurations

Environment configurations are stored in the `environments/` directory. The root-level files are used by the main workspace:

- **`sandbox.tfvars`** - Sandbox environment configuration
- **`non-production.tfvars`** - Non-production environment configuration
- **`production.tfvars`** - Production environment configuration

Regional jobs run from the `regional/` working directory and use zone-specific files in `regional/environments/`:

- **`{zone}-{env}.tfvars`** - One file per zone per environment (e.g., `us-east1-sandbox.tfvars`, `us-east4-production.tfvars`)

### Core Helpers Configuration

The `helpers.tofu` file configures the OpenTofu Core Helpers module which provides:

- **Logos workspace integration** - Fetches team infrastructure data from pt-logos foundational platform
- **Environment detection** - Automatically determines environment from workspace name
- **Project naming** - Generates standardized project names and descriptions
- **Labeling** - Provides consistent labels for cost tracking and governance
- **Team data** - Exposes team folder hierarchy, identity groups, and GitHub repositories

### Optional Variables

Key optional variables (all have defaults unless noted):

- **`datadog_enable`** - Enable Datadog integration (default: false)
- **`datadog_api_key`** - Datadog API key (required if `datadog_enable = true`)
- **`datadog_app_key`** - Datadog APP key (required if `datadog_enable = true`)
- **`google_customer_id`** - Google Workspace customer ID (default: "C01hd34v8")
- **`project_billing_account`** - The billing account ID (default: "01C550-A2C86B-B8F16B")
- **`project_monthly_budget_amount`** - Monthly budget in USD (default: 5)

### State Configuration Variables

These variables are required for backend configuration and are provided by GitHub Actions workflows:

- **`state_bucket`** - The name of the GCS bucket to store state files
- **`state_kms_encryption_key`** - The KMS encryption key for state and plan files
- **`state_prefix`** - The prefix for state files in the GCS bucket

### Additional Variables

- **`kubernetes_project_monthly_budget_amount`** - Monthly budget in USD for Kubernetes projects (default: 5)
- **`osinfra_io_ns_delegations`** - NS delegation records for environment-level zones in the production `osinfra.io` zone (default: [])
- **`vpc_service_projects`** - Map of service projects to attach to the Shared VPC (default: {})

## Outputs for Downstream Consumption

This infrastructure provides outputs designed for consumption by downstream repositories:

### `project_id`

The Google Cloud project ID for use in downstream resource creation.

### `project_number`

The Google Cloud project number for use in IAM bindings and other resources requiring the numeric project identifier.

### `service_accounts`

GitHub Actions service accounts created for each team with repositories, including email addresses, names, and unique IDs for downstream authentication and access control.

### `storage_buckets`

Encrypted GCS buckets created for OpenTofu state storage, with bucket names and URLs for each team's infrastructure automation.

### `teams`

Complete team infrastructure information from the logos foundational platform including:

- Team metadata (display name, team type)
- Folder hierarchy (team type folder, team folder ID, environment folder IDs)
- Identity groups with email addresses, display names, descriptions, and roles

### `workload_identity_pools`

Workload Identity Pools created for secure external authentication, providing pool names and IDs for GitHub Actions integration.

### `workload_identity_providers`

Workload Identity Pool Providers configured for OIDC authentication with GitHub Actions, including provider names and IDs.

### `kubernetes_projects`

Google Cloud project IDs and numbers for Kubernetes workloads, organized per team with environment information.

### `osinfra_io_dns_zone`

The environment-level DNS zone information (`dns_name`, `name`, `name_servers`) for the zone managed in this environment — `osinfra.io` in production, `sb.osinfra.io` in sandbox, `nonprod.osinfra.io` in non-production. Used to populate `osinfra_io_ns_delegations` in the production `environments/production.tfvars` after sandbox and non-production are first deployed.

### `regional_subnets`

Subnet details organized by region, consumed by regional deployments for GKE cluster configuration.

### `vpc_name`

The Shared VPC network name, consumed by regional deployments when creating subnets and cloud NAT.

These outputs provide downstream repositories with comprehensive infrastructure information for consistent resource deployment, secure authentication, and access control management.

## DNS Delegation

Corpus manages a three-tier DNS delegation hierarchy rooted at `osinfra.io`. Each environment gets its own zone, and team zones (created only for teams with GKE clusters) are automatically delegated into the appropriate environment zone.

**How it works:**

- `module.osinfra_io_dns` creates the env-level zone in every environment (`osinfra.io` in prod, `sb.osinfra.io` in sandbox, `nonprod.osinfra.io` in non-production)
- `google_dns_record_set.team_ns_delegation` automatically delegates each team's zone into the env-level zone on every apply — no manual steps required for team zones
- `google_dns_record_set.osinfra_io_ns_delegation` delegates `sb.osinfra.io` and `nonprod.osinfra.io` into the production `osinfra.io` zone — nameservers are populated in `environments/production.tfvars` after sandbox and non-production are first deployed

## Module Dependencies

This configuration leverages the following infrastructure modules:

### [pt-arche-google-project](https://github.com/osinfra-io/pt-arche-google-project)

Provides Google Cloud project creation with:

- CIS compliance logging and monitoring
- Budget controls and cost management
- Required API enablement
- Standardized project configuration

### [pt-arche-datadog-google-integration](https://github.com/osinfra-io/pt-arche-datadog-google-integration)

Provides Datadog integration with:

- Cloud Security Posture Management (CSPM)
- Security Command Center integration
- Automated monitoring setup
- Compliance and security visibility

### [pt-arche-google-storage-bucket](https://github.com/osinfra-io/pt-arche-google-storage-bucket)

Provides encrypted GCS bucket creation with:

- KMS encryption for state file security
- Standardized bucket configuration
- Consistent labeling and naming
- Multi-environment support

### [pt-arche-core-helpers](https://github.com/osinfra-io/pt-arche-core-helpers)

Provides foundational platform capabilities:

- Logos workspace integration for team data
- Standardized labeling and tagging
- Environment detection and naming
- Cross-workspace data sharing

### [pt-arche-google-network](https://github.com/osinfra-io/pt-arche-google-network)

Provides Google Cloud networking infrastructure with:

- Shared VPC with service networking peering
- Private and public DNS zone management
- Regional subnets with GKE secondary IP ranges
- Cloud NAT for outbound connectivity

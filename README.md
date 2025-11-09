# Corpus

**[GitHub Actions](https://github.com/osinfra-io/corpus/actions):**

[![Dependabot](https://github.com/osinfra-io/corpus/actions/workflows/dependabot.yml/badge.svg)](https://github.com/osinfra-io/corpus/actions/workflows/dependabot.yml)

## 📄 Repository Description

This repository provides Infrastructure as Code (IaC) automation for the **Corpus** team infrastructure. As part of the **Platform Team** family, it implements standardized Google Cloud project creation with CIS compliance, Datadog monitoring integration, and foundational team infrastructure.

The infrastructure automates the creation of:

- **Google Cloud Project** with CIS compliance features, budget controls, and required APIs
- **Datadog Integration** with Cloud Security Posture Management (CSPM) and Security Command Center
- **Team Infrastructure** using the logos foundational platform for consistent labeling and governance
- **Multi-environment Support** with sandbox, non-production, and production configurations

This establishes team-specific infrastructure while maintaining consistency with organizational standards and foundational platform practices.

## 🏭 Platform Information

- Documentation: [docs.osinfra.io](https://docs.osinfra.io/product-guides/google-cloud-platform/corpus)
- Service Interfaces: [github.com](https://github.com/osinfra-io/corpus/issues/new/choose)

## <img align="left" width="35" height="35" src="https://github.com/osinfra-io/github-organization-management/assets/1610100/39d6ae3b-ccc2-42db-92f1-276a5bc54e65"> Development

Our focus is on the core fundamental practice of platform engineering, Infrastructure as Code.

>Open Source Infrastructure (as Code) is a development model for infrastructure that focuses on open collaboration and applying relative lessons learned from software development practices that organizations can use internally at scale. - [Open Source Infrastructure (as Code)](https://www.osinfra.io)

To avoid slowing down stream-aligned teams, we want to open up the possibility for contributions. The Open Source Infrastructure (as Code) model allows team members external to the platform team to contribute with only a slight increase in cognitive load. This section is for developers who want to contribute to this repository, describing the tools used, the skills, and the knowledge required, along with OpenTofu documentation.

See the [documentation](https://docs.osinfra.io/fundamentals/development-setup) for setting up a development environment.

### 🛠️ Tools

- [pre-commit](https://github.com/pre-commit/pre-commit)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pre-commit-hooks)

### 📋 Skills and Knowledge

Links to documentation and other resources required to develop and iterate in this repository successfully.

- [google cloud platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [google cloud platform iam](https://cloud.google.com/iam/docs/overview)
- [google cloud platform cis benchmarks](https://cloud.google.com/security-command-center/docs/cis-benchmarks)
- [datadog cloud security posture management](https://docs.datadoghq.com/security/cloud_security_management/)
- [datadog google cloud integration](https://docs.datadoghq.com/integrations/google_cloud_platform/)

## Architecture

The infrastructure creates:

- **Google Cloud Project** with standardized naming, CIS compliance logging, budget controls, and required APIs
- **Datadog Integration** with Cloud Security Posture Management (CSPM) and Security Command Center integration
- **Team Infrastructure** leveraging logos foundational platform for consistent labeling, environment detection, and governance
- **Multi-environment Support** with configurations for sandbox, non-production, and production deployments

## Interface

### Environment-Specific Configurations

Environment configurations are stored in the `environments/` directory:

- **`sandbox.tfvars`** - Sandbox environment configuration
- **`non-production.tfvars`** - Non-production environment configuration
- **`production.tfvars`** - Production environment configuration

### Required Variables

The following variables must be provided for deployment:

- **`billing_project`** - The quota project for user_project_override
- **`project_cis_2_2_logging_sink_project_id`** - The CIS 2.2 logging sink benchmark project ID
- **`project_folder_id`** - The numeric ID of the folder where the project should be created
- **`workload_identity_pool_name`** - The workload identity pool name for authentication

### Optional Variables

Variables with defaults that can be customized:

- **`billing_users_group_id`** - The numeric ID of the billing users group (default: "03dy6vkm4a7ag9g")
- **`datadog_enable`** - Enable Datadog integration (default: false)
- **`project_billing_account`** - The billing account ID (default: "01C550-A2C86B-B8F16B")
- **`project_monthly_budget_amount`** - Monthly budget in USD (default: 5)

### Sensitive Variables

The following variables contain sensitive data and should be provided through secure methods:

- **`datadog_api_key`** - Datadog API key (required if `datadog_enable = true`)
- **`datadog_app_key`** - Datadog APP key (required if `datadog_enable = true`)

## Outputs for Downstream Consumption

This infrastructure provides outputs designed for consumption by downstream repositories:

### `project_id`

The Google Cloud project ID for use in downstream resource creation.

### `project_number`

The Google Cloud project number for use in IAM bindings and other resources requiring the numeric project identifier.

### `teams`

Complete team infrastructure information from the logos foundational platform including:

- Team metadata (display name, team type)
- Folder hierarchy (team type folder, team folder ID, environment folder IDs)
- Identity groups with email addresses, display names, descriptions, and roles

These outputs provide downstream repositories with foundational infrastructure information for consistent resource deployment and access control management.

## Module Dependencies

This configuration leverages the following infrastructure modules:

### [opentofu-google-project](https://github.com/osinfra-io/opentofu-google-project)

Provides Google Cloud project creation with:

- CIS compliance logging and monitoring
- Budget controls and cost management
- Required API enablement
- Standardized project configuration

### [opentofu-datadog-google-integration](https://github.com/osinfra-io/opentofu-datadog-google-integration)

Provides Datadog integration with:

- Cloud Security Posture Management (CSPM)
- Security Command Center integration
- Automated monitoring setup
- Compliance and security visibility

### [opentofu-core-helpers](https://github.com/osinfra-io/opentofu-core-helpers)

Provides foundational platform capabilities:

- Logos workspace integration for team data
- Standardized labeling and tagging
- Environment detection and naming
- Cross-workspace data sharing

## Validation Rules

### Project Configuration

- Project must be deployed within appropriate folder hierarchy
- CIS logging sink project must be accessible
- Workload identity pool must exist and be accessible
- Budget amount must be positive number

### Environment Consistency

- Environment configurations must align with logos foundational platform
- Team naming must follow organizational standards
- Resource labeling must be consistent across environments

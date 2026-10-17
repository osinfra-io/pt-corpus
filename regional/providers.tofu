terraform {
  # State and Plan Encryption
  # https://opentofu.org/docs/language/state/encryption

  # The default key provider, method, and enforced plan/state encryption are supplied by the
  # called workflow through TF_ENCRYPTION and merged with this configuration.

  encryption {
    remote_state_data_sources {
      default {
        method = method.aes_gcm.default
      }
    }
  }

  # Requiring Providers
  # https://opentofu.org/docs/language/providers/requirements#requiring-providers

  required_providers {

    # Google Cloud Platform Provider
    # https://search.opentofu.org/provider/hashicorp/google/latest/docs

    google = {
      source = "hashicorp/google"
    }

    # Random Provider
    # https://search.opentofu.org/provider/hashicorp/random/latest/docs

    random = {
      source = "hashicorp/random"
    }
  }
}

# Google Cloud Platform Provider
# https://search.opentofu.org/provider/hashicorp/google/latest/docs

provider "google" {
  region = module.core_helpers.region
}

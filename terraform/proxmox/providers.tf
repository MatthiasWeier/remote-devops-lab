# ---------------------------------------------------------------------------------------------------------------------
# This file configures the Terraform providers used in the root configuration.
# The Proxmox provider `Telmate/proxmox` is defined here.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    # The Proxmox provider by Telmate.
    # Make sure you use a stable version.
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9" # Or a more specific version
    }
  }
}

# Proxmox Provider Configuration
provider "proxmox" {
  # The API URL of your Proxmox VE server.
  # This can be set via a variable (see variables.tf).
  pm_api_url = var.proxmox_api_url

  # API token ID and secret for authentication.
  # These should be provided via environment variables (e.g., PM_API_TOKEN_ID, PM_API_TOKEN_SECRET)
  # or a `secrets.tfvars` file to keep them secure.
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # (Optional) If your Proxmox server uses a self-signed certificate,
  # you can disable SSL verification. Not recommended in production!
  # pm_tls_insecure = true

  # (Optional) Path to a PEM-formatted client certificate.
  # pm_client_cert = "/path/to/client.crt"
  # pm_client_key  = "/path/to/client.key"
}

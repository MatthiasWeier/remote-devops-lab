terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url

  # The token format is 'ID=SECRET'
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"

  insecure = true # Allowed for self-signed certificates
}
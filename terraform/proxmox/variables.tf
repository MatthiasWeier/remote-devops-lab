# ---------------------------------------------------------------------------------------------------------------------
# This file defines all input variables for the root configuration.
# These variables can be set externally (e.g., via a .tfvars file or environment variables).
# ---------------------------------------------------------------------------------------------------------------------

# Proxmox API settings
variable "proxmox_api_url" {
  description = "The URL of the Proxmox VE API endpoint (e.g., https://your-proxmox-host:8006/api2/json)"
  type        = string
  # Default value is optional, but recommended if it often remains the same
  # default     = "https://your-proxmox-host:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "The ID of the Proxmox API token (e.g., user@realm!token_name)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The secret of the Proxmox API token"
  type        = string
  sensitive   = true # Marks the variable as sensitive to hide it in logs
}

variable "proxmox_node_name" {
  description = "The name of the Proxmox node where the VMs should be created."
  type        = string
  # default     = "pve" # Example: Replace this with your node name
}

variable "ssh_public_key_path" {
  description = "The path to the public SSH key to be injected into the VMs."
  type        = string
  # Default value can be adjusted here, e.g., "~/id_rsa.pub"
  default = "~/.ssh/id_rsa.pub"
}

variable "vms" {
  description = "Map of VMs to create with their specifications."
  type = map(object({
    vmid       = number
    clone_from = string
    cores      = number
    memory     = number
    disk_size  = number
    ip_address = string
    gateway    = string
  }))
  default = {}
}

variable "network_bridge" {
  description = "The Proxmox network bridge to use (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "ssh_password" {
  description = "SSH password for the matt user on VMs"
  type        = string
  sensitive   = true
}

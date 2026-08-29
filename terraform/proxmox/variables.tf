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
  description = "Map of K3s cluster VMs to create with their specifications."
  type = map(object({
    vmid                = number
    template_vm_id      = number
    role                = string # "control-plane" or "worker"
    cores               = number
    memory              = number
    disk_size           = number
    secondary_disk_size = optional(number) # e.g. for Longhorn storage on worker nodes
    ip_address          = string
    gateway             = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for vm in var.vms : contains(["control-plane", "worker"], vm.role)
    ])
    error_message = "Each VM's role must be either \"control-plane\" or \"worker\"."
  }

  validation {
    condition     = length([for vm in var.vms : vm if vm.role == "control-plane"]) == 1
    error_message = "Exactly one VM in the vms map must have role = \"control-plane\"."
  }
}

variable "network_bridge" {
  description = "The Proxmox network bridge to use (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

# Firewall settings (see firewall.tf)
variable "management_cidr" {
  description = <<-EOT
    The trusted LAN subnet allowed to reach SSH (22), the K3s API (6443), and
    (implicitly, since it's inside this same CIDR) the router doing the actual
    80/443 port-forward. Deliberately a single flat /24 rather than a narrower
    management-only range - this is a home LAN, not a segmented office network,
    and splitting it further would just be rules to maintain for no real gain.
  EOT
  type        = string
  default     = "192.168.178.0/24"
}

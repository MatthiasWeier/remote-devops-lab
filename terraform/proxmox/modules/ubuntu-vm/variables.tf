# ---------------------------------------------------------------------------------------------------------------------
# This file defines the input variables for the `ubuntu-vm` module.
# These variables allow the module to be flexibly configured.
# ---------------------------------------------------------------------------------------------------------------------

# General VM settings
variable "name" {
  description = "The display name of the VM in Proxmox."
  type        = string
}

variable "vmid" {
  description = "The unique VM ID for the new VM."
  type        = number
}

variable "node_name" {
  description = "The name of the Proxmox node on which the VM should be created."
  type        = string
}

variable "template_vm_id" {
  description = "The numeric VM ID of the Cloud-Init template to clone from (the bpg/proxmox clone block requires a numeric ID, not a template name)."
  type        = number
}

variable "role" {
  description = "The role of this node in the K3s cluster (e.g. 'control-plane' or 'worker'). Used for tagging and Ansible inventory grouping."
  type        = string

  validation {
    condition     = contains(["control-plane", "worker"], var.role)
    error_message = "role must be either \"control-plane\" or \"worker\"."
  }
}

# Hardware specifications
variable "cores" {
  description = "Number of CPU cores for the VM."
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM of the VM in MB."
  type        = number
  default     = 2048 # 2 GB
}

variable "disk_size" {
  description = "Size of the main disk of the VM in GB."
  type        = number
  default     = 32
}

variable "secondary_disk_size" {
  description = "Size in GB of an optional secondary raw data disk (attached as scsi1), e.g. for Longhorn storage. Leave null to skip."
  type        = number
  default     = null
}

# Network settings
variable "network_bridge" {
  description = "The name of the Proxmox network bridge to which the VM will be connected."
  type        = string
  default     = "vmbr0" # Example: Adjust this to your Proxmox configuration
}

variable "ip_address" {
  description = "The static IP address of the VM with CIDR notation (e.g., '192.168.1.100/24')."
  type        = string
}

variable "gateway" {
  description = "The default gateway for the VM (e.g., '192.168.1.1')."
  type        = string
}

# SSH settings for Cloud-Init
variable "ssh_keys" {
  description = "A list of public SSH keys to be injected into the VM."
  type        = list(string)
  default     = []
}

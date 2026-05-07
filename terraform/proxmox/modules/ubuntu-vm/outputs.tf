# ---------------------------------------------------------------------------------------------------------------------
# This file defines the output values for the `ubuntu-vm` module.
# These values can be referenced by the calling root module.
# ---------------------------------------------------------------------------------------------------------------------

# Output the VM ID of the created VM
output "vmid" {
  description = "The ID of the created Proxmox VM."
  value       = proxmox_vm_qemu.ubuntu_vm.vmid
}

# Output the name of the created VM
output "name" {
  description = "The name of the created Proxmox VM."
  value       = proxmox_vm_qemu.ubuntu_vm.name
}

# Output the assigned IP address
# Note that the IP address is only available in the guest system after booting and Cloud-Init configuration.
# Terraform cannot directly read the actually assigned IP address of the guest system,
# unless the guest agent is installed and configured, and the provider explicitly supports this (which Telmate/proxmox does not directly via an attribute).
# We output the configured IP address that is injected via Cloud-Init here.
output "ip_address" {
  description = "The configured IP address assigned to the VM (via Cloud-Init)."
  value       = var.ip_address
}

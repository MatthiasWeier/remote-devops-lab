output "vmid" {
  description = "The ID of the created Proxmox VM."
  value       = proxmox_virtual_environment_vm.proxmox_vm.vm_id
}

output "name" {
  description = "The name of the created Proxmox VM."
  value       = proxmox_virtual_environment_vm.proxmox_vm.name
}

output "ip_address" {
  description = "The configured IP address assigned to the VM."
  value       = var.ip_address
}

output "role" {
  description = "The K3s role of this node ('control-plane' or 'worker')."
  value       = var.role
}
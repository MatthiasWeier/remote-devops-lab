# ---------------------------------------------------------------------------------------------------------------------
# This file defines the output values of the root configuration.
# These values can be displayed after applying the Terraform configuration and referenced by other configurations.
# ---------------------------------------------------------------------------------------------------------------------

# Output all VM IP addresses as a map
output "vm_ip_addresses" {
  description = "Map of VM names to their IP addresses"
  value = {
    for name, vm in module.ubuntu_vm : name => vm.ip_address
  }
}

# Output all VM IDs as a map
output "vm_ids" {
  description = "Map of VM names to their VM IDs"
  value = {
    for name, vm in module.ubuntu_vm : name => vm.vmid
  }
}

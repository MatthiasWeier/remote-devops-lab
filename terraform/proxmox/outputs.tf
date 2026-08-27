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

# Output Ansible inventory file path
output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

# Output K3s control-plane node(s)
output "control_plane_nodes" {
  description = "Map of K3s control-plane nodes with their details"
  value = {
    for name, vm in local.control_plane_nodes : name => {
      ip_address = vm.ip_address
      vmid       = vm.vmid
    }
  }
}

# Output K3s worker nodes
output "worker_nodes" {
  description = "Map of K3s worker nodes with their details"
  value = {
    for name, vm in local.worker_nodes : name => {
      ip_address = vm.ip_address
      vmid       = vm.vmid
    }
  }
}

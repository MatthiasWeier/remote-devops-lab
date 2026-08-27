# ---------------------------------------------------------------------------------------------------------------------
# This file defines the main configuration for your Proxmox resources.
# Modules are called and other resources are instantiated here.
# ---------------------------------------------------------------------------------------------------------------------

# Dynamic VM deployment using for_each
# Each VM is created based on the vms variable map
module "ubuntu_vm" {
  for_each = var.vms

  source = "./modules/ubuntu-vm"

  # General VM settings
  name           = each.key
  node_name      = var.proxmox_node_name
  template_vm_id = each.value.template_vm_id
  role           = each.value.role
  vmid           = each.value.vmid

  # Hardware specifications
  cores               = each.value.cores
  memory              = each.value.memory
  disk_size           = each.value.disk_size
  secondary_disk_size = each.value.secondary_disk_size

  # Network settings
  network_bridge = var.network_bridge
  ip_address     = each.value.ip_address
  gateway        = each.value.gateway

  # Cloud-Init settings
  # trimspace() avoids a spurious "forces replacement" diff on every future
  # plan/apply if the key file's trailing newline ever differs from what's
  # in state - file() reads bytes exactly, and a stray newline is otherwise
  # invisible but reads as a changed key to Terraform.
  ssh_keys = [trimspace(file(var.ssh_public_key_path))]
}

# Split K3s nodes into control_plane and workers by their explicit role
# attribute (set in the vms map), not by fragile name matching.
locals {
  control_plane_nodes = {
    for name, vm in module.ubuntu_vm : name => vm
    if vm.role == "control-plane"
  }

  worker_nodes = {
    for name, vm in module.ubuntu_vm : name => vm
    if vm.role == "worker"
  }
}

# Generate Ansible inventory file from template
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../ansible/inventories/production/hosts.ini"

  content = templatefile("${path.module}/inventory.tftpl", {
    control_plane_nodes = local.control_plane_nodes
    worker_nodes        = local.worker_nodes
  })

  depends_on = [module.ubuntu_vm]
}

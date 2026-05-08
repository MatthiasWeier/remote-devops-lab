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
  name        = each.key
  node_name   = var.proxmox_node_name
  clone_from  = each.value.clone_from
  vmid        = each.value.vmid

  # Hardware specifications
  cores       = each.value.cores
  memory      = each.value.memory
  disk_size   = each.value.disk_size

  # Network settings
  network_bridge = var.network_bridge
  ip_address     = each.value.ip_address
  gateway        = each.value.gateway

  # Cloud-Init settings
  ssh_keys    = [file(var.ssh_public_key_path)]
}

# Separate VMs into docker_nodes and proxy_nodes based on naming convention
locals {
  docker_nodes = {
    for name, vm in module.ubuntu_vm : name => vm
    if can(regex("webserver|docker", name))
  }

  proxy_nodes = {
    for name, vm in module.ubuntu_vm : name => vm
    if can(regex("database|proxy", name))
  }
}

# Generate Ansible inventory file from template
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../ansible/inventories/production/hosts.ini"
  
  content = templatefile("${path.module}/inventory.tftpl", {
    docker_nodes   = local.docker_nodes
    proxy_nodes    = local.proxy_nodes
    ssh_password   = var.ssh_password
  })

  depends_on = [module.ubuntu_vm]
}

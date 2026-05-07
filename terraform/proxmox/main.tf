# ---------------------------------------------------------------------------------------------------------------------
# This file defines the main configuration for your Proxmox resources.
# Modules are called and other resources are instantiated here.
# ---------------------------------------------------------------------------------------------------------------------

# Example implementation of the Ubuntu VM Module
# This module creates an Ubuntu VM with Cloud-Init on your Proxmox host.
module "ubuntu_webserver" {
  source = "./modules/ubuntu-vm"

  # General VM settings
  name        = "web-server-01" # Display name of the VM in Proxmox
  node_name   = var.proxmox_node_name # Proxmox node where the VM will be created
  clone_from  = "ubuntu-cloudinit-template" # Name of the Cloud-Init template
  vmid        = 100 # Unique VM ID

  # Hardware specifications
  cores       = 2 # Number of CPU cores
  memory      = 4096 # RAM in MB
  disk_size   = 50 # Size of the main disk in GB

  # Network settings
  network_bridge = "vmbr0" # Name of the network bridge
  ip_address     = "192.168.1.100/24" # Static IP address of the VM with CIDR
  gateway        = "192.168.1.1" # Default gateway

  # Cloud-Init settings
  ssh_keys    = [file(var.ssh_public_key_path)] # Path to the public SSH key for Cloud-Init
  # You can add more Cloud-Init parameters here, e.g., user_data.
}

# Add more VM instances here by calling the module again.
# For example, for a database server:
/*
module "ubuntu_dbserver" {
  source = "./modules/ubuntu-vm"

  name        = "db-server-01"
  node_name   = var.proxmox_node_name
  clone_from  = "ubuntu-cloudinit-template"
  vmid        = 101

  cores       = 4
  memory      = 8192
  disk_size   = 100

  network_bridge = "vmbr0"
  ip_address     = "192.168.1.101/24"
  gateway        = "192.168.1.1"

  ssh_keys    = [file(var.ssh_public_key_path)]
}
*/

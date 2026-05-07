# ---------------------------------------------------------------------------------------------------------------------
# This file defines the main resources of the `ubuntu-vm` module.
# The `proxmox_vm_qemu` resource is configured here to create an Ubuntu VM.
# ---------------------------------------------------------------------------------------------------------------------

# Resource for creating a QEMU-based virtual machine in Proxmox
resource "proxmox_vm_qemu" "ubuntu_vm" {
  # General VM settings
  name        = var.name       # Display name of the VM
  vmid        = var.vmid       # Unique VM ID
  target_node = var.node_name  # Proxmox node where the VM should run
  desc        = "Ubuntu VM managed by Terraform" # Description of the VM

  # Resource allocation (CPU, RAM)
  cores   = var.cores   # Number of CPU cores
  memory  = var.memory  # RAM in MB

  # Cloud-Init settings
  # Cloud-Init is crucial for automating initial configuration.
  # It requires a Cloud-Init enabled template in Proxmox.
  cloudinit_cdrom_storage = "local-lvm" # Storage location for the Cloud-Init ISO (must be accessible)
  ciuser                  = "ubuntu"    # Default username for Cloud-Init
  cipassword              = "password" # A temporary password, Cloud-Init can change this
  sshkeys                 = var.ssh_keys # List of public SSH keys to be authorized
  # Example for user_data (optional, for advanced scripts on first boot)
  # user_data = base64encode(templatefile("${path.module}/cloud-init-script.tpl", {
  #   hostname = var.name
  # }))

  # VM source (cloning from a template)
  clone {
    vm_id = data.proxmox_vm_qemu.template.vm_id # The VM ID of the template
    full  = true # Performs a full clone (not a linked clone)
  }

  # Disk settings
  disk {
    disk_id = 0 # The ID of the disk (usually 0 for the boot disk)
    size    = var.disk_size # Size of the hard disk in GB
    type    = "scsi" # Disk type (e.g., scsi, sata, ide)
    storage = "local-lvm" # Storage pool for the hard disk
    # cache   = "writeback" # (Optional) Cache mode for the hard disk
  }

  # Network settings
  network {
    bridge = var.network_bridge # The Proxmox network bridge to which the VM will be connected
    model  = "virtio" # Virtual network adapter model
    # IP settings via Cloud-Init
    # Proxmox injects these IP settings into the guest system via Cloud-Init.
    # Make sure your template is Cloud-Init enabled.
    ip = var.ip_address
    gw = var.gateway
  }

  # Other settings
  os_type = "cloud-init" # Defines the OS type for Proxmox
  agent   = 1 # Enables the QEMU guest agent for better integration
  boot    = "scsi0" # Boot order (boot from SCSI disk 0)
  # power_down_wait_seconds = 30 # Shutdown wait time
}

# Data source for retrieving information about the Cloud-Init template
# Make sure you have an Ubuntu Cloud-Init template prepared in Proxmox.
# This template should have a name specified in `var.clone_from`.
data "proxmox_vm_qemu" "template" {
  name        = var.clone_from
  target_node = var.node_name
}

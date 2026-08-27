resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  name        = var.name
  vm_id       = var.vmid
  node_name   = var.node_name
  description = "Managed by Terraform (BPG Provider) - K3s ${var.role}"
  tags        = ["k3s", var.role]

  # Clone from an existing Cloud-Init template (identified by numeric VM ID)
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # Required for Terraform/Proxmox to report VM state (IP, running status) reliably,
  # and a prerequisite for clean K3s node bootstrapping.
  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES" # Best compatibility for Proxmox 9
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.disk_size
  }

  # Optional blank secondary data disk (e.g. for Longhorn). No `file_id` and no
  # clone source here - this is what makes Proxmox allocate genuinely empty
  # raw storage on scsi1 instead of trying to clone/import an image onto it.
  # file_format must be explicit "raw": local-lvm is LVM-Thin block storage
  # and rejects qcow2 (the provider's default for a fresh disk) with
  # "unsupported format 'qcow2'" (LvmThinPlugin.pm).
  dynamic "disk" {
    for_each = var.secondary_disk_size != null ? [var.secondary_disk_size] : []
    content {
      datastore_id = "local-lvm"
      interface    = "scsi1"
      size         = disk.value
      file_format  = "raw"
    }
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = var.ssh_keys
      username = "matt"
    }
  }
}

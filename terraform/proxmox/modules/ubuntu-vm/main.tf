resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  name        = var.name
  vm_id       = var.vmid
  node_name   = var.node_name
  description = "Managed by Terraform (BPG Provider)"

  # Clone configuration
  clone {
    vm_id = 1001 # Replace with your Template-ID (e.g. 999)
    full  = true
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
    file_id      = "local:iso/debian-13-generic-amd64.qcow2" # Optional: if not cloning
    interface    = "scsi0"
    size         = var.disk_size
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
# Proxmox Terraform Module - K3s Cluster Deployment

A modular Terraform configuration for provisioning a K3s Kubernetes cluster (1 control-plane + N workers) on Proxmox, using the `bpg/proxmox` provider.

## Overview

This Terraform configuration allows you to:
- Deploy a K3s cluster (control-plane + worker nodes) with a single `terraform apply`
- Assign **different hardware specs per role** (CPU cores, RAM, disk size)
- Use **static IP addressing** (required for predictable K3s node communication)
- Manage all nodes through a **centralized variable map** (`vms`), each tagged with an explicit `role`
- Clone from a **Debian Cloud-Init template**, with the QEMU guest agent enabled
- Auto-generate an **Ansible inventory** (`control_plane` / `workers` groups) for a follow-up K3s playbook run

## Quick Start

### Prerequisites

1. **Proxmox VE** installed and running (I use Proxmox Virtual Environment 9.1.9)
2. **Terraform** (v1.0+) installed on your local machine
3. **Proxmox API Token** with sufficient permissions:
   - `VM.Allocate`
   - `VM.Clone`
   - `VM.Config.Disk`
   - `VM.Config.Memory`
   - `VM.Config.Network`
   - `VM.Config.HWType`
   - `VM.PowerMgmt`

4. **Debian 13 Cloud-Init Template** in Proxmox (VM ID 999 or adjust in module)
5. **SSH Public Key** available locally (e.g., `~/.ssh/id_rsa.pub`)

### Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd terraform/proxmox
   ```

2. **Create your `.tfvars` file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your Proxmox details:**
   ```hcl
   proxmox_api_url          = "https://your-proxmox-host:8006/api2/json"
   proxmox_api_token_id     = "root@pam!terraform"
   proxmox_api_token_secret = "your-secret-token"
   proxmox_node_name        = "pve"
   network_bridge           = "vmbr0"
   ssh_public_key_path      = "~/.ssh/id_ed25519.pub"
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Plan your deployment:**
   ```bash
   terraform plan
   ```

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Configuration

### VM Map Structure

Define your K3s nodes in `terraform.tfvars` using the `vms` map. Exactly one entry must have `role = "control-plane"`; the rest should be `role = "worker"`:

```hcl
vms = {
  "k3s-cp-01" = {
    vmid           = 510                  # Unique VM ID
    template_vm_id = 9000                 # Numeric VM ID of the Cloud-Init template
    role           = "control-plane"      # "control-plane" or "worker"
    cores          = 2                    # CPU cores
    memory         = 4096                 # RAM in MB
    disk_size      = 30                   # Disk size in GB
    ip_address     = "192.168.1.160/24"   # Static IP with CIDR
    gateway        = "192.168.1.1"        # Default gateway
  }

  "k3s-worker-01" = {
    vmid           = 511
    template_vm_id = 9000
    role           = "worker"
    cores          = 2
    memory         = 6144
    disk_size      = 40
    ip_address     = "192.168.1.161/24"
    gateway        = "192.168.1.1"
  }

  "k3s-worker-02" = {
    vmid           = 512
    template_vm_id = 9000
    role           = "worker"
    cores          = 2
    memory         = 6144
    disk_size      = 40
    ip_address     = "192.168.1.162/24"
    gateway        = "192.168.1.1"
  }
}
```

> Find your template's numeric VM ID on the Proxmox host with `qm list | grep <template-name>`.

## File Structure

```
terraform/proxmox/
├── main.tf                          # Main configuration with for_each loop
├── variables.tf                     # Input variables (including vms map)
├── outputs.tf                       # Output values (VM IPs and IDs)
├── providers.tf                     # Proxmox provider configuration
├── terraform.tfvars.example         # Example configuration (copy to terraform.tfvars)
├── .gitignore                       # Git ignore rules
├── README.md                        # This file
└── modules/
    └── ubuntu-vm/
        ├── main.tf                  # VM resource definition
        ├── variables.tf             # Module input variables
        └── outputs.tf               # Module outputs
```

## Common Commands

### Plan Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Destroy All VMs
```bash
terraform destroy
```

### Destroy Specific VM
```bash
terraform destroy -target='module.ubuntu_vm["vm-name"]'
```

### View Outputs
```bash
terraform output
```

### View Specific Output
```bash
terraform output vm_ip_addresses
```

## Outputs

After applying, Terraform outputs:

```
vm_ids = {
  "k3s-cp-01"     = 510
  "k3s-worker-01" = 511
  "k3s-worker-02" = 512
}

vm_ip_addresses = {
  "k3s-cp-01"     = "192.168.1.160/24"
  "k3s-worker-01" = "192.168.1.161/24"
  "k3s-worker-02" = "192.168.1.162/24"
}

control_plane_nodes = {
  "k3s-cp-01" = {
    ip_address = "192.168.1.160/24"
    vmid       = 510
  }
}

worker_nodes = {
  "k3s-worker-01" = {
    ip_address = "192.168.1.161/24"
    vmid       = 511
  }
  "k3s-worker-02" = {
    ip_address = "192.168.1.162/24"
    vmid       = 512
  }
}
```

An Ansible inventory is also generated at `ansible/inventories/production/hosts.ini` with `[control_plane]` and `[workers]` groups, ready for a K3s installation playbook.

## SSH Access

Once VMs are deployed, SSH into them (cloud-init provisions the `matt` user with your injected public key):

```bash
ssh -i ~/.ssh/id_ed25519 matt@192.168.1.160
```

## Troubleshooting

### Error: "permissions for user/token are not sufficient"

**Solution:** Ensure your Proxmox API token has all required permissions:
- Go to **Datacenter → Permissions → API Tokens**
- Edit your token and enable: `VM.Monitor`, `VM.Allocate`, `VM.Clone`, `VM.Config.*`, `VM.PowerMgmt`

### Error: "template not found" / clone fails

**Solution:** Verify the template's numeric VM ID in Proxmox:
```bash
# In Proxmox shell
qm list | grep debian
```

Update `template_vm_id` in your `terraform.tfvars` to match the actual template's numeric VM ID (not its name).

### VMs created but no IP assigned

**Solution:** Ensure the Debian 13 template has Cloud-Init installed and configured:
```bash
# On the template VM
cloud-init --version
```

### Terraform state issues

**Solution:** Never commit `*.tfstate` files to Git. They're already in `.gitignore`.

## Advanced Usage

### Add a New Worker Node

Simply add a new entry to the `vms` map in `terraform.tfvars` with `role = "worker"`:

```hcl
vms = {
  # ... existing nodes ...

  "k3s-worker-03" = {
    vmid           = 513
    template_vm_id = 9000
    role           = "worker"
    cores          = 2
    memory         = 6144
    disk_size      = 40
    ip_address     = "192.168.1.163/24"
    gateway        = "192.168.1.1"
  }
}
```

Note: only one node may have `role = "control-plane"` — the variable validation will reject a second one.

Then run:
```bash
terraform plan
terraform apply
```

### Remove a VM

Delete the entry from the `vms` map and run:
```bash
terraform apply
```

Terraform will automatically destroy the removed VM.

### Modify VM Specs

Edit the VM's properties in `terraform.tfvars` and run:
```bash
terraform plan
terraform apply
```

**Note:** Some changes (like disk size) may require VM recreation.

## Security Best Practices

1. **Never commit `terraform.tfvars`** to Git (use `.tfvars.example` instead)
2. **Protect your API token secret** - use environment variables:
   ```bash
   export TF_VAR_proxmox_api_token_secret="your-secret"
   ```
3. **Use SSH keys** instead of passwords for VM access
4. **Enable MFA** on your Proxmox account
5. **Rotate API tokens** regularly

## Module Details

### Module: `ubuntu-vm`

**Location:** `modules/ubuntu-vm/`

**Purpose:** Encapsulates the creation of a single Proxmox VM with Cloud-Init support and the QEMU guest agent enabled, tagged by K3s role.

**Inputs:**
- `name` - VM display name
- `vmid` - Unique VM ID
- `node_name` - Proxmox node name
- `template_vm_id` - Numeric VM ID of the Cloud-Init template to clone
- `role` - `"control-plane"` or `"worker"` (used for tags and inventory grouping)
- `cores` - CPU cores
- `memory` - RAM in MB
- `disk_size` - Disk size in GB
- `network_bridge` - Network bridge name
- `ip_address` - Static IP with CIDR
- `gateway` - Default gateway
- `ssh_keys` - List of SSH public keys

**Outputs:**
- `vmid` - Created VM ID
- `name` - VM name
- `ip_address` - Configured IP address
- `role` - K3s role of the node

## Contributing

To improve this configuration:
1. Test changes in a non-production environment
2. Update documentation
3. Submit a pull request

## License

This project is part of the Remote DevOps Portfolio.

## Support

For issues or questions:
1. Check the **Troubleshooting** section above
2. Review Proxmox logs: `journalctl -u pveproxy -f`
3. Check Terraform logs: `TF_LOG=DEBUG terraform plan`

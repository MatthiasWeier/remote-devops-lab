# Proxmox Terraform Module - Modular VM Deployment

A fully modular Terraform configuration for deploying multiple Debian 13 VMs on Proxmox with completely different hardware specifications.

## Overview

This Terraform configuration allows you to:
- Deploy an **arbitrary number of VMs** with a single `terraform apply`
- Assign **completely different hardware specs** to each VM (CPU cores, RAM, disk size)
- Use **dynamic IP addressing** with static CIDR notation
- Manage all VMs through a **centralized variable map** (`vms`)
- Clone from **Debian 13 Cloud-Init templates**

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
   proxmox_api_url         = "https://your-proxmox-host:8006/api2/json"
   proxmox_api_token_id    = "root@pam!terraform"
   proxmox_api_token_secret = "your-secret-token"
   proxmox_node_name       = "pve"
   network_bridge          = "vmbr0"
   ssh_public_key_path     = "~/.ssh/id_rsa.pub"
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

Define your VMs in `terraform.tfvars` using the `vms` map:

```hcl
vms = {
  "vm-name-1" = {
    vmid       = 100                    # Unique VM ID
    clone_from = "debian-13-cloudinit"  # Template name
    cores      = 2                      # CPU cores
    memory     = 2048                   # RAM in MB
    disk_size  = 32                     # Disk size in GB
    ip_address = "192.168.1.100/24"     # Static IP with CIDR
    gateway    = "192.168.1.1"          # Default gateway
  }

  "vm-name-2" = {
    vmid       = 101
    clone_from = "debian-13-cloudinit"
    cores      = 4
    memory     = 8192
    disk_size  = 100
    ip_address = "192.168.1.101/24"
    gateway    = "192.168.1.1"
  }
}
```

### Example: Real-World Deployment

```hcl
vms = {
  "web-server" = {
    vmid       = 100
    clone_from = "debian-13-cloudinit"
    cores      = 2
    memory     = 2048      # 2 GB
    disk_size  = 32
    ip_address = "192.168.1.100/24"
    gateway    = "192.168.1.1"
  }

  "database-server" = {
    vmid       = 101
    clone_from = "debian-13-cloudinit"
    cores      = 4
    memory     = 8192      # 8 GB
    disk_size  = 100
    ip_address = "192.168.1.101/24"
    gateway    = "192.168.1.1"
  }

  "cache-server" = {
    vmid       = 102
    clone_from = "debian-13-cloudinit"
    cores      = 2
    memory     = 4096      # 4 GB
    disk_size  = 50
    ip_address = "192.168.1.102/24"
    gateway    = "192.168.1.1"
  }
}
```

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
  "Terra-debian-database"  = 501
  "Terra-debian-webserver" = 500
}

vm_ip_addresses = {
  "Terra-debian-database"  = "192.168.1.151/24"
  "Terra-debian-webserver" = "192.168.1.150/24"
}
```

## SSH Access

Once VMs are deployed, SSH into them:

```bash
ssh -i ~/.ssh/id_rsa.pub debian@192.168.1.100
```

## Troubleshooting

### Error: "permissions for user/token are not sufficient"

**Solution:** Ensure your Proxmox API token has all required permissions:
- Go to **Datacenter → Permissions → API Tokens**
- Edit your token and enable: `VM.Monitor`, `VM.Allocate`, `VM.Clone`, `VM.Config.*`, `VM.PowerMgmt`

### Error: "clone_from template not found"

**Solution:** Verify the template name exists in Proxmox:
```bash
# In Proxmox shell
qm list | grep debian
```

Update `clone_from` in your `terraform.tfvars` to match the actual template name.

### VMs created but no IP assigned

**Solution:** Ensure the Debian 13 template has Cloud-Init installed and configured:
```bash
# On the template VM
cloud-init --version
```

### Terraform state issues

**Solution:** Never commit `*.tfstate` files to Git. They're already in `.gitignore`.

## Advanced Usage

### Add a New VM

Simply add a new entry to the `vms` map in `terraform.tfvars`:

```hcl
vms = {
  # ... existing VMs ...
  
  "new-server" = {
    vmid       = 103
    clone_from = "debian-13-cloudinit"
    cores      = 2
    memory     = 2048
    disk_size  = 32
    ip_address = "192.168.1.103/24"
    gateway    = "192.168.1.1"
  }
}
```

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

**Purpose:** Encapsulates the creation of a single Proxmox VM with Cloud-Init support.

**Inputs:**
- `name` - VM display name
- `vmid` - Unique VM ID
- `node_name` - Proxmox node name
- `clone_from` - Template name to clone
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

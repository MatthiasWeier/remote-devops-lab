# System Setup Role

This role prepares your servers for Docker deployment by automatically extending disk space and validating system requirements.

## What Does This Role Do?

### 1. Automatic Disk Expansion (LVM)
When you create a VM from a cloud image, the root partition often doesn't use the full disk space. This role automatically expands it:

- Extends the root partition (`/dev/sda2`)
- Extends the LVM partition (`/dev/sda5`)
- Resizes the physical volume
- Extends the logical volume to use all available space
- Resizes the filesystem

**Result:** Your server uses the full 52GB disk instead of just a few GB.

### 2. Pre-Flight Validation
After expansion, the role checks that you have at least **10 GB of free space** on the root filesystem. If not, the playbook fails with a clear error message.

## When Does This Run?

This role runs **first** on every server, before Docker is installed. It's part of both:
- `playbooks/docker.yml` (for Docker nodes)
- `playbooks/proxy.yml` (for Proxy nodes)

## Configuration

Edit `ansible/roles/system_setup/defaults/main.yml` to customize:

```yaml
# Minimum required free disk space in bytes (10 GB)
min_disk_space_bytes: 10737418240

# Partition and LVM configuration (for Debian/Ubuntu)
root_partition: "/dev/sda2"
lvm_partition: "/dev/sda5"
lvm_root_device: "/dev/mapper/debian--vg-root"
```

**Note:** These values are specific to Debian cloud images. If your servers use different partitions, update these values.

## Troubleshooting

### "growpart: NOCHANGE: partition X is size ... it cannot be grown"
This is **not an error**. It means the partition is already at maximum size. The role handles this gracefully.

### "CRITICAL: Root filesystem does not have minimum required free space!"
Your disk expansion failed or your disk is too small. Check:
1. Is the VM disk actually 52GB?
2. Did the LVM expansion complete successfully?
3. Try manually running: `sudo lvextend -l +100%FREE /dev/mapper/debian--vg-root && sudo resize2fs /dev/mapper/debian--vg-root`

### "Permission denied" when running growpart
The role uses `become: yes` (sudo). Make sure your Ansible user can run sudo without a password, or provide the sudo password.

## What Gets Installed?

- `cloud-guest-utils` - Provides the `growpart` command for partition expansion

## Files Modified on Target Server

- `/dev/sda2` - Root partition (extended)
- `/dev/sda5` - LVM partition (extended)
- `/dev/mapper/debian--vg-root` - Logical volume (extended)
- Filesystem (resized)

## Example Output

```
TASK [Display disk expansion summary]
Disk expansion completed:
Root partition before: 10.00 GB
Root partition after: 50.00 GB

TASK [Pre-flight check - Verify minimum disk space available]
SUCCESS: Root filesystem has sufficient free space!
Available: 45.50 GB
Minimum required: 10.00 GB
```

## Next Steps

After this role completes successfully, the `docker_setup` role installs Docker on the expanded filesystem.

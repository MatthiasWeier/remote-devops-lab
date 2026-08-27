#!/bin/bash
# Creates a reusable Debian 13 (trixie) Cloud-Init template on Proxmox.
#
# Run this ONCE, directly on the Proxmox host (as root via the Proxmox shell
# or SSH) - NOT from your workstation, and NOT via Terraform. Terraform's
# `clone` block in modules/ubuntu-vm needs this template's numeric VM ID
# (template_vm_id) to already exist before `terraform apply` can work.

set -euo pipefail

TEMPLATE_VMID=9000
TEMPLATE_NAME="debian-13-cloudinit-template"
STORAGE="local-lvm"
BRIDGE="vmbr0"
IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
IMAGE_FILE="/tmp/debian-13-genericcloud-amd64.qcow2"

if qm status "${TEMPLATE_VMID}" &>/dev/null; then
  echo "VM ID ${TEMPLATE_VMID} already exists on this host - aborting to avoid overwriting it."
  echo "Pick a different TEMPLATE_VMID at the top of this script, or remove the existing VM first."
  exit 1
fi

echo "Downloading Debian 13 generic cloud image..."
wget -q --show-progress -O "${IMAGE_FILE}" "${IMAGE_URL}"

echo "Ensuring libguestfs-tools (virt-customize) is installed..."
if ! command -v virt-customize &>/dev/null; then
  apt-get update -qq
  apt-get install -y libguestfs-tools
fi

# Debian's genericcloud image does NOT ship qemu-guest-agent pre-installed.
# Without it, Proxmox's guest-agent query (which the bpg/proxmox Terraform
# provider relies on to detect VM readiness/IP) never gets a response and
# `terraform apply` hangs indefinitely. Bake the package - and an explicit
# service enable, rather than trusting the postinst to do it - directly
# into the image before it ever becomes a template.
#
# LIBGUESTFS_BACKEND=direct: Proxmox hosts don't run libvirtd by default:
# without this, virt-customize tries libvirt first and fails.
echo "Installing and enabling qemu-guest-agent inside the image..."
export LIBGUESTFS_BACKEND=direct
virt-customize -a "${IMAGE_FILE}" \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent'

echo "Creating VM shell ${TEMPLATE_VMID}..."
qm create "${TEMPLATE_VMID}" \
  --name "${TEMPLATE_NAME}" \
  --memory 2048 \
  --cores 2 \
  --net0 "virtio,bridge=${BRIDGE}" \
  --scsihw virtio-scsi-pci \
  --ostype l26

echo "Importing disk into storage '${STORAGE}'..."
qm importdisk "${TEMPLATE_VMID}" "${IMAGE_FILE}" "${STORAGE}"

echo "Attaching imported disk as scsi0..."
qm set "${TEMPLATE_VMID}" --scsi0 "${STORAGE}:vm-${TEMPLATE_VMID}-disk-0"

echo "Adding a Cloud-Init drive..."
qm set "${TEMPLATE_VMID}" --ide2 "${STORAGE}:cloudinit"

echo "Setting boot disk and serial console (required for cloud images)..."
qm set "${TEMPLATE_VMID}" --boot order=scsi0
qm set "${TEMPLATE_VMID}" --serial0 socket --vga serial0

echo "Enabling the QEMU guest agent flag on the template..."
qm set "${TEMPLATE_VMID}" --agent enabled=1

echo "Converting VM ${TEMPLATE_VMID} into a template..."
qm template "${TEMPLATE_VMID}"

rm -f "${IMAGE_FILE}"

echo ""
echo "Done. Template '${TEMPLATE_NAME}' created as VM ID ${TEMPLATE_VMID}."
echo ""
echo "Next: set this in terraform/proxmox/terraform.tfvars for every node entry:"
echo "  template_vm_id = ${TEMPLATE_VMID}"
echo ""
echo "Note: qemu-guest-agent is now baked into this template and enabled,"
echo "and cloud-init auto-grows the root partition to the cloned disk size on"
echo "first boot - no manual steps needed after terraform apply."

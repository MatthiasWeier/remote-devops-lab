# ---------------------------------------------------------------------------------------------------------------------
# Zero-trust micro-segmentation for the K3s VMs via the Proxmox Datacenter Firewall.
#
# PRIORITY ZERO: the Proxmox HOST's own management access (its web UI on
# :8006, SSH to the hypervisor itself) is never touched by anything in this
# file. Every resource below is scoped to individual K3s guest VMs
# (proxmox_virtual_environment_firewall_options with node_name + vm_id, and a
# security group only those VMs reference) - nothing here is a Datacenter- or
# Node-level rule, and nothing here changes the Datacenter/Node default
# policy. The Proxmox host stays reachable exactly as it is today regardless
# of how badly a rule below is misconfigured.
#
# The one piece this file deliberately does NOT manage: the cluster-wide
# "Firewall: Enabled" checkbox at Datacenter > Firewall > Options
# (proxmox_virtual_environment_cluster_firewall's `enabled` attribute would
# be the Terraform-native way to do it). VM-level rules are silently inert
# until that global switch is on, but the switch itself has no rules of its
# own and defaults to policy ACCEPT at the Datacenter/Node level - flipping
# it on does not drop a single packet by itself, it only starts *evaluating*
# the VM-level rules defined here. It's left as a one-time manual step
# rather than a Terraform resource so that turning on segmentation is a
# deliberate, reversible-by-checkbox action, not something a
# `terraform apply` can silently re-enable after someone turned it off to
# debug a lockout:
#   pvesh set /cluster/firewall/options --enable 1
# (or Datacenter -> Firewall -> Options -> Firewall: Yes in the web UI)
#
# ROLLOUT ORDER (do not skip - this is what avoids an SSH lockout):
#   1. terraform apply with everything in this file present but the
#      Datacenter firewall switch still OFF. Confirms the plan is clean.
#   2. Verify: `pvesh get /nodes/<node>/qemu/<vmid>/firewall/rules` shows the
#      expected rule list for at least one VM, including the two GROUP
#      insertion rows (see the group-membership resource below).
#   3. Flip the Datacenter switch on (command above).
#   4. Immediately verify SSH still works from your management LAN. If it
#      doesn't, flip the switch back off - nothing here can lock you out of
#      the Proxmox host itself, only (at worst) the K3s guests.
#
# Rule evaluation is first-match-wins. Unlike some providers, `pos` on the
# provider's `rule` block is COMPUTED ONLY - the API assigns it from
# submission order, Terraform can't set it directly. Ordering is therefore
# controlled entirely by the ORDER these `rule { }` blocks are written below
# (including the order dynamic-block-generated rules land in, which follows
# for_each list order). Do not reorder these without understanding that the
# DROP-to-LAN egress rule must stay AFTER the internal-cluster-mesh and
# DNS-to-gateway ALLOWs, or nodes lose the ability to talk to the gateway
# and to each other.

locals {
  # Bare IPs (no /24 suffix) of every K3s node, for the internal cluster-mesh
  # rules below. Longhorn replica traffic, flannel VXLAN (8472/udp), kubelet
  # (10250), etc. all need this - rather than enumerate every K3s port (and
  # inevitably miss one), the mesh rules just ALLOW everything between these
  # specific node IPs.
  k3s_node_ips = [for vm in var.vms : split("/", vm.ip_address)[0]]

  # All nodes share one gateway in this flat-L2 homelab network - any VM's
  # value is representative, values()[0] just avoids hardcoding a node name.
  gateway_ip = values(var.vms)[0].gateway
}

# Defines the named rule set. This resource holds the actual ALLOW/DROP
# rules; it does NOT by itself apply them to anything - see the
# k3s_vm_group_membership resource below, which is what actually attaches
# this group to each VM.
resource "proxmox_virtual_environment_cluster_firewall_security_group" "k3s_dmz" {
  name    = "k3s-dmz"
  comment = "K3s node baseline: SSH/API/HTTP(S) in from LAN, full mesh between nodes, egress restricted to internet + gateway only."

  # --- Ingress ---------------------------------------------------------------

  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    source  = var.management_cidr
    log     = "nolog"
    comment = "SSH from the trusted LAN"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "6443"
    source  = var.management_cidr
    log     = "nolog"
    comment = "K3s API - harmless no-op on workers (nothing listens there), required on cp-01"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "80,443"
    source  = "0.0.0.0/0"
    log     = "nolog"
    comment = "Traefik ingress - public HTTP(S), this is the whole point of exposing services externally"
  }

  # Full-mesh internal cluster traffic. Dynamic so this stays correct if
  # nodes are ever added/removed in terraform.tfvars without hand-editing
  # rules. Each node gets one ALLOW-all-protocols/ports rule per node IP as
  # source (self-loops are harmless no-ops, not worth filtering out).
  dynamic "rule" {
    for_each = local.k3s_node_ips
    content {
      type    = "in"
      action  = "ACCEPT"
      source  = rule.value
      log     = "nolog"
      comment = "K3s internal mesh (flannel VXLAN, kubelet, Longhorn replica traffic, etc.) from ${rule.value}"
    }
  }

  # --- Egress ------------------------------------------------------------------
  # output_policy is DROP (set per-VM in the firewall_options resources
  # below), so only what's explicitly ALLOWed here gets out. Order matters:
  # the ALLOWs below MUST be evaluated before the DROP-to-LAN rule, because
  # the gateway and the other node IPs all live inside var.management_cidr.

  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "udp"
    dport   = "53,67,68"
    dest    = local.gateway_ip
    log     = "nolog"
    comment = "DNS + DHCP to the router (dumb consumer gateway also serves as resolver)"
  }

  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "53"
    dest    = local.gateway_ip
    log     = "nolog"
    comment = "DNS over TCP (fallback for large responses) to the router"
  }

  dynamic "rule" {
    for_each = local.k3s_node_ips
    content {
      type    = "out"
      action  = "ACCEPT"
      dest    = rule.value
      log     = "nolog"
      comment = "K3s internal mesh egress to ${rule.value}"
    }
  }

  rule {
    type    = "out"
    action  = "DROP"
    dest    = var.management_cidr
    log     = "info"
    comment = "Deny lateral movement to the rest of the LAN (NAS, PCs, smart home) - the actual point of this whole file. Everything above this line that needed LAN access already got an explicit ALLOW."
  }

  rule {
    type    = "out"
    action  = "ACCEPT"
    dest    = "0.0.0.0/0"
    log     = "nolog"
    comment = "Internet outbound (package/image pulls, Let's Encrypt ACME, etc.) - the LAN subset of 0.0.0.0/0 was already consumed by the DROP rule above, so this only ever matches real internet traffic"
  }
}

# Enables the per-VM firewall on every K3s node. Deliberately per-VM (not a
# single blanket resource) so a future non-K3s VM added to this Proxmox host
# is NOT swept into this security group by accident - membership is
# explicit, one resource per module instance (see the group-membership
# resource below).
resource "proxmox_virtual_environment_firewall_options" "k3s_vm_firewall" {
  for_each = var.vms

  node_name = var.proxmox_node_name
  vm_id     = each.value.vmid

  enabled  = true
  dhcp     = false
  ipfilter = false
  # Nothing gets in or out except what the k3s-dmz group's rules ALLOW.
  input_policy  = "DROP"
  output_policy = "DROP"

  depends_on = [module.ubuntu_vm]
}

# Attaches the k3s-dmz security group's rules to each VM. A "GROUP"
# insertion in Proxmox's rule model isn't a normal ALLOW/DROP rule - it's a
# single directional row that says "evaluate the named group's rules here",
# which is why `action` is omitted and `security_group` is set instead.
#
# VERIFY AFTER FIRST APPLY (this is the one part of this file with no
# hands-on-cluster confirmation yet - the provider schema confirms
# `security_group` is a valid field on a rule block, but not the exact
# runtime semantics of one-row-per-direction vs. one-row-total):
#   pvesh get /nodes/<node>/qemu/<vmid>/firewall/rules
# You should see the k3s-dmz group's rules represented (either inlined or as
# GROUP references) for BOTH directions. If only one direction shows up,
# the two `rule` blocks below may need to collapse into one with `type`
# omitted - check the provider's current examples at
# https://github.com/bpg/terraform-provider-proxmox before changing this.
resource "proxmox_virtual_environment_firewall_rules" "k3s_vm_group_membership" {
  for_each = var.vms

  node_name = var.proxmox_node_name
  vm_id     = each.value.vmid

  rule {
    type           = "in"
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.k3s_dmz.name
    comment        = "Insert k3s-dmz group rules (ingress)"
  }

  rule {
    type           = "out"
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.k3s_dmz.name
    comment        = "Insert k3s-dmz group rules (egress)"
  }

  depends_on = [proxmox_virtual_environment_firewall_options.k3s_vm_firewall]
}

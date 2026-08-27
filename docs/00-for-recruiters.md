# Homelab GitOps Kubernetes Platform

**A self-hosted, GitOps-managed Kubernetes platform built from bare metal — provisioned, bootstrapped, and operated entirely through code.**

This document is a quick, non-technical overview for anyone skimming this repo from a resume, portfolio link, or LinkedIn post. For the full step-by-step build log and replication guide, see [`01-setup-and-runbook.md`](./01-setup-and-runbook.md).

---

## The short version

Starting from a bare Proxmox VE server, this project stands up a production-shaped Kubernetes platform without touching a GUI for the repeatable parts:

- **Terraform** provisions the virtual machines
- **Ansible** bootstraps the operating system and the Kubernetes cluster itself
- **ArgoCD** takes over from there — every application on the cluster is deployed and kept in sync purely by pushing YAML to this Git repository (GitOps)
- **Longhorn** gives the cluster replicated, VM-loss-tolerant storage
- **cert-manager + Let's Encrypt** issue and renew TLS certificates automatically

The result: a 3-node K3s Kubernetes cluster, running real self-hosted applications (a Prometheus/Grafana monitoring stack, a photo backup service, a recipe manager, a personal wiki), where recovering from a lost VM or a lost disk is a `terraform apply` and an Ansible run away — not a weekend of manual reinstallation.

## Why this exists

The goal was to actually *build* the infrastructure patterns that production teams run in the real world — not just read about them. That meant deliberately choosing the harder, more honest path at every layer:

- A real cloud provider Terraform provider (`bpg/proxmox`), not a toy example
- A real distributed storage system (Longhorn) instead of hoping the hardware never fails
- A real GitOps controller (ArgoCD) instead of `kubectl apply` by hand
- Real bugs, hit and fixed under real constraints — see below

## What it demonstrates

| Area | What was built |
|---|---|
| **Infrastructure as Code** | A modular Terraform configuration (`for_each`-driven, one module per node role) provisioning VMs, static networking, and cloud-init on Proxmox |
| **Configuration Management** | Ansible playbooks bootstrapping K3s itself (server + token-based worker join) and preparing block storage, with secrets kept out of git via Ansible Vault |
| **Container Orchestration** | A 3-node K3s cluster (1 control-plane, 2 workers), sized and validated against real host resource constraints |
| **Distributed Storage** | Longhorn, backed by a dedicated Terraform-provisioned disk per worker, replicating data across nodes |
| **GitOps** | ArgoCD `Application` manifests as the single source of truth for every workload on the cluster |
| **Security & TLS** | Automated certificate issuance via cert-manager + Let's Encrypt (HTTP-01), least-privilege API token design |
| **Real-world troubleshooting** | Several genuine infrastructure bugs were hit and diagnosed during the build — not glossed over. Highlights: |

- Diagnosed a hung `terraform apply` down to a missing `qemu-guest-agent` inside the base VM image, and fixed the image-build pipeline (`virt-customize`) to bake it in permanently.
- Caught and prevented a **near-miss data-loss incident**: Linux block-device naming (`/dev/sda` vs `/dev/sdb`) is not guaranteed to be consistent across VMs. A hardcoded device name in an early playbook version would have run `mkfs` against a live root filesystem — caught before it happened, and replaced with structural disk detection (find the disk with no partition table, rather than trusting a device name).
- Resolved a Kubernetes API server hard limit (a 256KiB annotation size cap) that broke a standard `kubectl apply` of ArgoCD's own installation manifests, by switching to server-side apply.
- Diagnosed a storage-backend incompatibility (LVM-Thin storage silently defaulting to an unsupported disk image format) that was blocking VM creation entirely.

## Tech stack

Proxmox VE · Terraform (`bpg/proxmox`) · Ansible (+ Vault) · K3s · Longhorn · ArgoCD · cert-manager · Let's Encrypt · Helm · Prometheus / Grafana

## Want the details?

The full build — every command run, every bug hit, and how to replicate the whole thing from scratch — is documented in [`01-setup-and-runbook.md`](./01-setup-and-runbook.md). The root [`README.md`](../README.md) tracks the project's ongoing roadmap.

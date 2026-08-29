# Remote DevOps Portfolio

**A real, self-hosted GitOps Kubernetes platform running on my own Proxmox hardware** — Terraform → Ansible → K3s → ArgoCD, with Sealed Secrets, Prometheus/Alertmanager alerting to my phone, and a CI pipeline that validates every manifest before it reaches the cluster. Every bug hit along the way is documented with its root cause, not just the fix. Started as a cloud DevOps portfolio project on Oracle Cloud Infrastructure (still below); the homelab is now the main, actively-developed part.

[![Validate GitOps manifests](https://github.com/MatthiasWeier/remote-devops-lab/actions/workflows/validate-gitops.yml/badge.svg)](https://github.com/MatthiasWeier/remote-devops-lab/actions/workflows/validate-gitops.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Last commit](https://img.shields.io/github/last-commit/MatthiasWeier/remote-devops-lab)

📄 **[Overview for recruiters](docs/00-for-recruiters.md)** — what this is and why it exists, in plain language.
📄 **[Full setup & runbook](docs/01-setup-and-runbook.md)** — architecture diagram, step-by-step replication guide, and every bug hit along the way (with root causes, not just fixes).

---

## Tech Stack
* **Cloud Provider:** Oracle Cloud Infrastructure (OCI)
* **Virtualization (Homelab):** Proxmox VE, provisioned via the `bpg/proxmox` Terraform provider
* **Infrastructure as Code:** Terraform
* **Configuration Management:** Ansible (+ Ansible Vault for secrets)
* **Containerization:** Docker & Docker Compose
* **Container Orchestration:** K3s (lightweight Kubernetes)
* **Distributed Block Storage:** Longhorn
* **GitOps:** ArgoCD
* **Traffic Routing & SSL:** Traefik / Nginx Proxy Manager
* **Monitoring & Management:** Portainer, Uptime Kuma, Watchtower (Docker layer) · kube-prometheus-stack (Kubernetes layer, GitOps-deployed)

---

## Project Roadmap

### Phase 1: Foundation & Security
Focus: Establish an indestructible baseline on the "Always Free" tier.
- [x] **Account Hardening:** Enabled MFA for OCI login and set a budget alert (> €1.00).
- [x] **Base Instance:** Provisioned an "Ampere A1" instance (ARM) with 4 Cores, 24 GB RAM, and Ubuntu.
- [x] **Cloud Network (VCN):** Configured Ingress Rules (opened ports 80 & 443).
- [x] **Docker Setup:** Installed Docker, Docker Compose, and Portainer for management (via the `docker_setup` / `deploy_compose` Ansible roles).

### Phase 2: Infrastructure as Code
Focus: Learn automation and resource management.
- [x] **Terraform Basics:** Local setup and API keys configured via `.oci/config`.
- [x] **The Sandbox:** Wrote scripts to automatically provision and destroy x86 test servers (`terraform apply` & `terraform destroy`).
- [x] **Version Control:** Established a secure GitHub repository (including strict `.gitignore` to protect tfstate files and credentials).

### Phase 3: Traffic & Automation
Focus: Professional traffic routing and container updates.
- [x] **Reverse Proxy:** Nginx Proxy Manager running as a Docker container, deployed via the `nginx_proxy` Ansible role.
- [ ] **Domain Routing:** Configured DNS records and Let's Encrypt for automatic SSL certificates.
- [ ] **Watchtower:** Implemented automated update management for running containers.

### Phase 4: Showcase Portfolio
Focus: Deploy visible applications that utilize the server's resources.
- [ ] **Monitoring:** Deployed Uptime Kuma to monitor cloud services and the local homelab.
- [ ] **Workspaces:** Deployed Kasm in Docker to leverage the 24 GB RAM of the ARM instance for desktop streaming.
- [ ] **Clean-Up:** Ensured all manual and Terraform-generated x86 resources are completely destroyed.

### Phase 5: Homelab Kubernetes Platform (Proxmox + K3s)
Focus: Stand up a self-hosted, GitOps-managed Kubernetes platform on bare-metal Proxmox — "cattle, not pets" for the homelab.
- [x] **Proxmox IaC:** Migrated to the `bpg/proxmox` Terraform provider; modular `ubuntu-vm` module, `for_each`-driven, provisions a 3-node K3s cluster (1 control-plane + 2 workers) from a single `vms` map.
- [x] **Cloud-Init:** Static IPs, injected SSH public key, and the QEMU guest agent enabled on every node.
- [x] **Dynamic Ansible Inventory:** Terraform generates `ansible/inventories/production/hosts.ini` with `[control_plane]` / `[workers]` groups straight from node `role`, ready for K3s bootstrapping playbooks.
- [x] **K3s Cluster Bootstrap:** `ansible/playbooks/install-k3s.yml` installs the K3s server on the control-plane, retrieves its node token, and joins both workers as agents.
- [x] **Distributed Block Storage:** Longhorn, backed by a Terraform-provisioned secondary disk (`scsi1`, 50GB) attached to worker nodes only; formatted, and mounted at `/var/lib/longhorn` via `ansible/playbooks/setup-longhorn-nodes.yml`.
- [x] **GitOps Bootstrap:** ArgoCD installed via `kubernetes/bootstrap/install-argocd.sh`.
- [x] **First GitOps App:** `kube-prometheus-stack` deployed as an ArgoCD `Application` (`kubernetes/apps/kube-prometheus-stack.yaml`), with Prometheus, Alertmanager, and Grafana PVCs all backed by Longhorn — proving persistent, replicated storage survives pod/node loss end to end.
- [ ] **K3s Ingress:** K3s ships with Traefik by default, but it isn't yet configured/exposed for the new `monitoring` namespace or future apps.

### Phase 6: Production Hardening & GitOps Maturity (Next Steps)
Focus: close the gap between "it works" and "it's operable." Not yet implemented — a candidate list for what's next.
- [x] **App-of-Apps pattern:** `kubernetes/apps/root-app.yaml` now watches `kubernetes/apps/` (non-recursive) directly. Every future top-level `.yaml` under that directory is auto-registered on `git push` — no more one-time manual `kubectl apply -f` per app.
- [ ] **Remote Terraform State:** `terraform.tfstate` is still local-only — no locking, no team-safety, no recovery if the machine running `terraform apply` is lost.
- [ ] **Longhorn Backups:** No S3/NFS backup target is configured — losing more worker VMs than Longhorn's replica count would still mean real data loss. Blocked on NAS arrival.
- [x] **GitOps Secrets Management:** Sealed Secrets controller deployed via ArgoCD; Longhorn UI's BasicAuth and Tandoor's DB credentials now live in git as `SealedSecret` objects, not created out-of-band. Immich's and BookStack's secrets are not yet migrated — see runbook.
- [x] **CI Validation:** `.github/workflows/validate-gitops.yml` runs yamllint, `kubectl kustomize` on every overlay, and kubeconform schema validation against upstream Kubernetes' OpenAPI schemas on every push/PR to `main`. Terraform/Ansible linting is still not covered.
- [x] **Alerting:** Alertmanager's default receiver now posts to an `ntfy-alertmanager` bridge in-cluster, which forwards to a private ntfy.sh topic with severity mapped to priority/tags. See runbook for the topic name.
- [ ] **K8s Ingress & TLS:** Decide between K3s's built-in Traefik and the existing Docker-based Nginx Proxy Manager for exposing Grafana etc. externally, then wire up cert-manager or NPM accordingly.

---

### Folder Structure

```text
remote-devops-lab/
├── .gitignore
├── README.md
│
├── terraform/
│   └── proxmox/
│       ├── main.tf
│       ├── providers.tf                 <-- bpg/proxmox provider
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars             <-- gitignored, holds real credentials + the vms map
│       ├── terraform.tfvars.example
│       ├── inventory.tftpl              <-- renders the Ansible inventory below
│       └── modules/
│           └── ubuntu-vm/               <-- one K3s node per for_each entry; optional Longhorn data disk
│               ├── main.tf
│               ├── variables.tf
│               ├── outputs.tf
│               └── providers.tf
│
├── ansible/
│   ├── ansible.cfg                      <-- Basic ansible settings
│   ├── inventories/
│   │   └── production/
│   │       ├── hosts.ini                <-- AUTO-GENERATED by Terraform! Do not edit manually.
│   │       └── group_vars/
│   │           ├── all.yml
│   │           ├── docker_nodes.yml     <-- Variables for all docker hosts
│   │           └── proxy_nodes.yml
│   │
│   ├── group_vars/
│   │   └── all/
│   │       └── vault.yml                <-- Ansible Vault-encrypted secrets (sudo password, etc.)
│   │
│   ├── playbooks/
│   │   ├── site.yml                     <-- Master playbook (Docker/proxy nodes)
│   │   ├── docker.yml                   <-- Maps docker role to VMs
│   │   ├── proxy.yml                    <-- Maps proxy role to VMs
│   │   ├── install-k3s.yml              <-- Bootstraps the K3s cluster itself (server + agent join)
│   │   └── setup-longhorn-nodes.yml     <-- Preps K3s workers' secondary disk for Longhorn
│   │
│   └── roles/
│       ├── system_setup/                <-- Root/LVM partition growth, disk pre-flight checks
│       │   └── tasks/main.yml
│       ├── docker_setup/                <-- Installs docker engine
│       │   └── tasks/main.yml
│       ├── deploy_compose/              <-- Generic role to copy and run compose files
│       │   └── tasks/main.yml
│       └── nginx_proxy/
│           └── tasks/main.yml
│
├── kubernetes/                          <-- GitOps layer for the K3s cluster
│   ├── bootstrap/
│   │   └── install-argocd.sh            <-- One-time ArgoCD install onto K3s
│   └── apps/
│       └── kube-prometheus-stack.yaml   <-- ArgoCD Application; Prometheus/Grafana PVCs on Longhorn
│
└── docker/
    ├── portainer/
    │   └── docker-compose.yml
    ├── nginx-proxy-manager/
    │   └── docker-compose.yml
    └── monitoring/
        ├── docker-compose.yml
        └── prometheus.yml               <-- Docker-Compose-based Prometheus (separate from the K8s stack above)
```
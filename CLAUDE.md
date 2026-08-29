# Working in this repo

Homelab GitOps Kubernetes platform: Terraform (Proxmox) → Ansible (K3s) → ArgoCD (`kubernetes/apps/`). Full architecture, every app, and every bug hit with its root cause: **`docs/01-setup-and-runbook.md`**. Read that file instead of asking for a recap — it's kept current and is more reliable than conversation memory.

Live cluster status + a human-readable overview also live in BookStack: `https://wiki.matt-host.de` → *Homelab Infrastructure* book.

## Things that will bite you if you don't know them

- **No App-of-Apps.** A new `kubernetes/apps/*.yaml` needs one manual `kubectl apply -f` to register with ArgoCD the first time. `git push` alone only updates apps ArgoCD already knows about.
- **ArgoCD `selfHeal` reverts direct `kubectl apply`.** If an Application has `automated.selfHeal: true`, a manual `kubectl apply` on its resources can get silently reverted seconds later if ArgoCD's git poll (~3 min default) hasn't caught up. Push to git first; if you need it live immediately, `kubectl -n argocd annotate application <name> argocd.argoproj.io/refresh=hard --overwrite` after pushing, not instead of.
- **Never pipe secrets from Windows through SSH** (`Get-Content x | ssh host "cmd"`). PowerShell's pipeline encoding has corrupted content this way more than once (a UTF-8 BOM breaking a htpasswd secret; a full file getting silently truncated on `kubectl apply`). Use `scp` for files, or build the content in a single remote `ssh host 'cmd'` session so nothing crosses the Windows/Linux boundary as piped text.
- **Grafana dashboards are GitOps-managed**, not edited in the UI: ConfigMaps labeled `grafana_dashboard: "1"` anywhere in the cluster, auto-imported by Grafana's sidecar. See `kubernetes/apps/manifests/observability-extras/dashboard-homelab-overview.yaml`.
- **Proxmox Datacenter Firewall is live and enforcing.** `terraform/proxmox/firewall.tf` defines the `k3s-dmz` rules; the enable/disable toggle itself is deliberately not Terraform-managed (manual, in the Proxmox UI) to avoid a `terraform apply` ever causing an SSH lockout.
- Only a Proxmox **API token** is available (no SSH/root to the hypervisor) — anything needing host-level shell access (temperature sensors, SMART) isn't achievable without the user doing it directly.

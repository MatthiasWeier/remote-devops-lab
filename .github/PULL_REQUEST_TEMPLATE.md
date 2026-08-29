## Description

What does this PR change, and why? Link to any related issue (e.g. `Closes #12`).

## Type of Change

- [ ] Bug fix
- [ ] New feature / new app or component
- [ ] Documentation update
- [ ] CI / tooling change
- [ ] Other (please describe):

## Which layer does this touch?

- [ ] Terraform (`terraform/proxmox/`)
- [ ] Ansible (`ansible/`)
- [ ] Kubernetes manifests (`kubernetes/apps/`)
- [ ] CI (`.github/workflows/`)
- [ ] Documentation only

## Checklist

- [ ] I ran `yamllint -c .yamllint.yml kubernetes ansible .github` locally and it passes
- [ ] I ran `kubectl kustomize` against any kustomize overlay I touched and it builds cleanly
- [ ] I ran `kubeconform` against any raw manifest directory I touched
- [ ] If this touches Terraform, I ran `terraform plan` and pasted the output below
- [ ] If this touches Ansible, I ran it with `--check` (or explain why that's not possible below)
- [ ] I did not commit any real secret, token, or credential (see `CONTRIBUTING.md`)
- [ ] I updated relevant documentation (`docs/01-setup-and-runbook.md` and/or `README.md`) if this changes how something is set up or operated

## Testing / Validation Output

Paste relevant `terraform plan`, `ansible-playbook --check`, or other command output here.

## Additional Notes

Anything a reviewer should know that isn't obvious from the diff.

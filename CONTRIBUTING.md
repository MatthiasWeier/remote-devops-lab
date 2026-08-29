# Contributing

Thanks for your interest in this project. It's primarily a personal homelab and portfolio piece (see [`docs/00-for-recruiters.md`](docs/00-for-recruiters.md)) run against real, physical hardware at home - so treat this as you would any small, single-maintainer open source project: contributions are welcome, but the maintainer's own priorities and available time come first, and review may not be immediate.

Good contributions for a repo like this: fixing a bug in the documented setup steps, correcting something in the "Bugs hit and fixed" log, improving the CI pipeline, or generalizing something that's currently hardcoded to this specific homelab so it's easier for someone else to replicate. Please open an issue before starting on anything larger than a small fix, so we can agree on the approach first.

## Getting started

1. **Fork** the repository and clone your fork.
2. Create a branch off `main` for your change:
   ```
   git checkout -b fix/short-description
   ```
3. Make your change. See "What gets touched where" below for which layer (Terraform/Ansible/Kubernetes) your change likely belongs in.
4. Run the same checks CI will run (see below) **before** pushing.
5. Commit with a clear message describing *why* the change is needed, not just what changed.
6. Push your branch and open a pull request against `main`. Fill in the PR template - it's short.

## What gets touched where

This repo has four layers, described in full in [`docs/01-setup-and-runbook.md`](docs/01-setup-and-runbook.md):

| Layer | Path | 
| ----- | ---- |
| Infrastructure provisioning | `terraform/proxmox/` |
| Node/OS configuration | `ansible/playbooks/`, `ansible/roles/` |
| Application deployment (GitOps) | `kubernetes/apps/` |
| CI | `.github/workflows/` |

Most contributions will be to the `kubernetes/` layer or documentation.

## Running the CI checks locally

`.github/workflows/validate-gitops.yml` runs three checks on every push/PR. Run them yourself first so you're not waiting on CI to find a typo:

```bash
# YAML lint (install: pip install yamllint)
yamllint -c .yamllint.yml kubernetes ansible .github

# Kustomize overlays build cleanly (kubectl ships with a built-in kustomize)
kubectl kustomize kubernetes/apps/manifests/tandoor-staging

# Schema-validate raw manifests (install: see https://github.com/yannh/kubeconform)
kubeconform -strict -ignore-missing-schemas -summary kubernetes/apps/manifests/<app-dir>/*.yaml
```

A pull request that fails any of these won't be merged until it's fixed, so it's worth running them locally first.

## Terraform and Ansible changes

There's no CI coverage for these yet (see the "Known limitations" section of the runbook) - if you're changing either, please run `terraform plan` / `ansible-playbook --check` yourself and paste the output in your PR description, since a reviewer can't run either against this specific hardware.

## Secrets

Never commit a real secret, credential, or anything that grants access on its own (API tokens, webhook URLs with embedded tokens, etc.) to this repository, even encrypted-looking or seemingly-obscure strings - this repo is public. Application secrets in this repo are either created out-of-band (see the comments at the top of the relevant manifest) or committed as a [Sealed Secret](https://github.com/bitnami-labs/sealed-secrets) (ciphertext only, decryptable only by this specific cluster). If your change needs a new secret, follow one of those two patterns - don't add a plaintext `Secret` manifest.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you're expected to uphold it.

## Reporting bugs vs. security issues

Regular bugs: please open a GitHub issue using the bug report template. Security vulnerabilities: please do **not** open a public issue - see [`SECURITY.md`](SECURITY.md) for how to report those privately.

# Security Policy

## Supported Versions

This repository is infrastructure-as-code for a live, single-environment homelab, not a versioned software package - there are no release tags or maintained branches other than `main`. `main` always reflects the currently-deployed configuration and is the only branch that receives security fixes.

| Branch | Supported |
| ------ | --------- |
| `main` | :white_check_mark: |
| any other branch/fork | :x: |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for a security vulnerability.** Publicly disclosing a weakness in a live, internet-facing homelab before it's fixed could expose it to real exploitation.

Instead, please report it privately using **[GitHub Security Advisories](../../security/advisories/new)** ("Report a vulnerability" under this repository's Security tab). This opens a private discussion with the maintainer and lets you receive credit once a fix is published, without the report being visible to the public in the meantime.

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce, or the specific manifest/configuration involved
- Any suggested remediation, if you have one

## What to Expect

This is a personal project maintained by one person outside of working hours, so response times aren't guaranteed - but security reports are treated as a priority over other issues and pull requests. You'll get an acknowledgement as soon as the report is seen, and updates as the issue is investigated and (if applicable) fixed.

## Scope

Most of what this repository describes runs behind a firewalled home network and is not directly reachable from the internet except through the specific domains listed in `docs/01-setup-and-runbook.md`. Reports about the actual configuration in this repo (Terraform, Ansible, Kubernetes manifests, CI workflows) are in scope. Reports about third-party software this repo merely deploys (Kubernetes itself, Longhorn, cert-manager, etc.) are best reported upstream to those projects directly, though you're welcome to flag them here too if you're not sure where they belong.

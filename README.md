# Remote DevOps Portfolio

**Goal:** Build a modern, scalable cloud environment

This repository documents my journey from manual click-ops to a fully automated cloud environment managed via Infrastructure as Code (IaC) on Oracle Cloud Infrastructure (OCI).

---

## Tech Stack
* **Cloud Provider:** Oracle Cloud Infrastructure (OCI)
* **Infrastructure as Code:** Terraform
* **Containerization:** Docker & Docker Compose
* **Traffic Routing & SSL:** Traefik / Nginx Proxy Manager
* **Monitoring & Management:** Portainer, Uptime Kuma, Watchtower

---

## Project Roadmap

### Phase 1: Foundation & Security
Focus: Establish an indestructible baseline on the "Always Free" tier.
- [x] **Account Hardening:** Enabled MFA for OCI login and set a budget alert (> €1.00).
- [x] **Base Instance:** Provisioned an "Ampere A1" instance (ARM) with 4 Cores, 24 GB RAM, and Ubuntu.
- [x] **Cloud Network (VCN):** Configured Ingress Rules (opened ports 80 & 443).
- [ ] **Docker Setup:** Installed Docker, Docker Compose, and Portainer for management.

### Phase 2: Infrastructure as Code
Focus: Learn automation and resource management.
- [x] **Terraform Basics:** Local setup and API keys configured via `.oci/config`.
- [x] **The Sandbox:** Wrote scripts to automatically provision and destroy x86 test servers (`terraform apply` & `terraform destroy`).
- [x] **Version Control:** Established a secure GitHub repository (including strict `.gitignore` to protect tfstate files and credentials).

### Phase 3: Traffic & Automation
Focus: Professional traffic routing and container updates.
- [ ] **Reverse Proxy:** Set up as a Docker container on the base instance.
- [ ] **Domain Routing:** Configured DNS records and Let's Encrypt for automatic SSL certificates.
- [ ] **Watchtower:** Implemented automated update management for running containers.

### Phase 4: Showcase Portfolio
Focus: Deploy visible applications that utilize the server's resources.
- [ ] **Monitoring:** Deployed Uptime Kuma to monitor cloud services and the local homelab.
- [ ] **Workspaces:** Deployed Kasm in Docker to leverage the 24 GB RAM of the ARM instance for desktop streaming.
- [ ] **Clean-Up:** Ensured all manual and Terraform-generated x86 resources are completely destroyed.

---

### Folder Structure

```text
remote-devops-lab/
├── .gitignore                  
├── README.md                   
├── terraform/                  
│   ├── main.tf                 
│   ├── provider.tf             
│   ├── variables.tf            
│   └── terraform.tfvars        
├── ansible/                    
│   ├── inventory.ini           
│   ├── setup-docker.yml        
│   └── deploy-proxy.yml        
└── docker/                     
    ├── portainer/
    │   └── docker-compose.yml
    ├── reverse-proxy/
    │   └── docker-compose.yml
    ├── watchtower/
    │   └── docker-compose.yml
    ├── monitoring/
    │   └── docker-compose.yml
    └── workspaces/
        └── docker-compose.yml

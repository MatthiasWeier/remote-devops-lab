# Deploy Compose Role

This role deploys Docker Compose applications (Portainer, Monitoring, Nginx Proxy Manager) on your servers.

## What Does This Role Do?

### 1. Create Docker Network
- Creates the `proxy-tier` network that all containers use to communicate

### 2. Create Application Directories
- Creates `/opt/docker/<app-name>/` for each application

### 3. Set File Permissions
- For Monitoring: Sets correct ownership for Prometheus (user 65534) and Grafana (user 472)
- This prevents "Permission denied" errors when containers try to write to volumes

### 4. Create Environment Files
- Generates `.env` files with secrets (passwords) from Ansible Vault
- These files are **not committed to Git** (they're in `.gitignore`)

### 5. Synchronize Docker Compose Files
- Copies `docker-compose.yml` and other files from your local machine to the server

### 6. Start Services
- Runs `docker-compose up` to start all containers
- Pulls the latest images automatically

## When Does This Run?

This role runs **after** `docker_setup` on every server:

**Docker Nodes** (`playbooks/docker.yml`):
- Deploys: Portainer, Monitoring (Prometheus + Grafana)

**Proxy Nodes** (`playbooks/proxy.yml`):
- Deploys: Nginx Proxy Manager

## Configuration

### Which Apps to Deploy?

In the playbooks, you specify which apps to deploy:

```yaml
# In playbooks/docker.yml
- role: deploy_compose
  vars:
    compose_apps:
      - portainer
      - monitoring

# In playbooks/proxy.yml
- role: deploy_compose
  vars:
    compose_apps:
      - nginx-proxy-manager
```

### Customize Passwords

Edit `ansible/group_vars/all/vault.yml` (encrypted):

```bash
ansible-vault edit ansible/group_vars/all/vault.yml
```

Then update:
```yaml
vault_portainer_admin_password: "your-password"
vault_grafana_admin_password: "your-password"
```

### Customize Ports

Edit the `docker-compose.yml` files in `docker/<app-name>/`:

```yaml
services:
  portainer:
    ports:
      - '8000:8000'  # Change first number to use different port
      - '9000:9000'
```

## What Gets Created on Target Server

```
/opt/docker/
├── portainer/
│   ├── docker-compose.yml
│   ├── .env                    (contains PORTAINER_ADMIN_PASSWORD)
│   └── data/                   (persistent storage)
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── .env                    (contains GRAFANA_ADMIN_PASSWORD)
│   ├── data/                   (Prometheus data, owned by user 65534)
│   └── grafana-storage/        (Grafana data, owned by user 472)
└── nginx-proxy-manager/
    ├── docker-compose.yml
    ├── data/                   (persistent storage)
    └── letsencrypt/            (SSL certificates)
```

## Troubleshooting

### "error mounting /opt/docker/monitoring/prometheus.yml ... not a directory"
The role automatically cleans this up. If it still fails:
```bash
ssh user@server
sudo rm -rf /opt/docker/monitoring/prometheus.yml
```

### "Permission denied" on Prometheus/Grafana volumes
The role sets permissions automatically. If it fails, manually fix:
```bash
sudo chown -R 65534:65534 /opt/docker/monitoring/data
sudo chown -R 472:472 /opt/docker/monitoring/grafana-storage
```

### "network proxy-tier not found"
The role creates this network automatically. If it fails:
```bash
docker network create proxy-tier
```

### Containers won't start
Check the logs:
```bash
docker-compose -f /opt/docker/<app-name>/docker-compose.yml logs
```

## Example Output

```
TASK [Create Docker network proxy-tier]
changed: [Terra-debian-webserver]

TASK [Create .env file for portainer]
changed: [Terra-debian-webserver]

TASK [Synchronize docker-compose files for portainer]
changed: [Terra-debian-webserver]

TASK [Start Docker Compose services for portainer]
changed: [Terra-debian-webserver]

TASK [Verify Docker Compose applications are running]
CONTAINER ID   NAMES              STATUS
abc123def456   portainer          Up 2 minutes
xyz789uvw012   prometheus         Up 2 minutes
```

## Manual Docker Compose Commands

Once deployed, you can manage containers:

```bash
# View running containers
docker ps

# View logs
docker-compose -f /opt/docker/portainer/docker-compose.yml logs -f

# Stop services
docker-compose -f /opt/docker/portainer/docker-compose.yml down

# Restart services
docker-compose -f /opt/docker/portainer/docker-compose.yml restart

# Pull latest images and restart
docker-compose -f /opt/docker/portainer/docker-compose.yml pull
docker-compose -f /opt/docker/portainer/docker-compose.yml up -d
```

## Accessing the Applications

After deployment, access them at:

- **Portainer**: `http://<server-ip>:9000`
- **Prometheus**: `http://<server-ip>:9090`
- **Grafana**: `http://<server-ip>:3000`
- **Nginx Proxy Manager**: `http://<server-ip>:81`

Default credentials:
- Portainer: `admin` / `admin`
- Grafana: `admin` / `admin`

## Next Steps

After this role completes, your applications are running! You can:
1. Access them via the URLs above
2. Configure reverse proxy rules in Nginx Proxy Manager
3. Set up monitoring dashboards in Grafana
4. Manage containers in Portainer

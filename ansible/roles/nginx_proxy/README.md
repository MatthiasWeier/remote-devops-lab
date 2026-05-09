# Nginx Proxy Role

This role deploys Nginx Proxy Manager using Docker Compose. It's an alternative to the `deploy_compose` role for managing reverse proxy configurations.

## What Does This Role Do?

### 1. Verify Docker Installation
- Checks that Docker is already installed before proceeding

### 2. Create Application Directory
- Creates `/opt/docker/nginx-proxy-manager/` directory

### 3. Synchronize Docker Compose Files
- Copies `docker-compose.yml` and configuration files from your local machine to the server

### 4. Start Nginx Proxy Manager
- Runs `docker-compose up` to start the Nginx Proxy Manager container
- Pulls the latest image automatically

### 5. Display Status
- Shows the deployment result and container status

## When Does This Run?

Currently, this role is **not used** in the main playbooks. Instead, the `deploy_compose` role with `nginx-proxy-manager` is used.

To use this role, you would add it to a playbook like:

```yaml
- name: Configure Proxy nodes
  hosts: proxy_nodes
  become: yes
  gather_facts: yes

  roles:
    - role: nginx_proxy
      tags:
        - nginx-proxy
```

## Configuration

Edit `ansible/roles/nginx_proxy/defaults/main.yml`:

```yaml
---
# Default variables for nginx_proxy role
nginx_proxy_port: 80
```

You can override the port in your playbook:

```yaml
- role: nginx_proxy
  vars:
    nginx_proxy_port: 8080
```

## What Gets Created on Target Server

```
/opt/docker/nginx-proxy-manager/
├── docker-compose.yml
├── data/                   (persistent storage for configs)
└── letsencrypt/            (SSL certificates)
```

## Accessing Nginx Proxy Manager

After deployment, access the admin interface at:

```
http://<server-ip>:81
```

Default credentials:
- Email: `admin@example.com`
- Password: `changeme`

## Troubleshooting

### "Docker must be installed before deploying nginx-proxy-manager"
The `docker_setup` role must run before this role. Make sure it's in your playbook:

```yaml
roles:
  - role: docker_setup
  - role: nginx_proxy
```

### Container won't start
Check the logs:
```bash
docker-compose -f /opt/docker/nginx-proxy-manager/docker-compose.yml logs
```

### Port 80 or 443 already in use
Change the port mapping in `docker/nginx-proxy-manager/docker-compose.yml`:

```yaml
ports:
  - '8080:80'    # Use 8080 instead of 80
  - '8443:443'   # Use 8443 instead of 443
```

## Manual Docker Compose Commands

```bash
# View running containers
docker ps

# View logs
docker-compose -f /opt/docker/nginx-proxy-manager/docker-compose.yml logs -f

# Stop services
docker-compose -f /opt/docker/nginx-proxy-manager/docker-compose.yml down

# Restart services
docker-compose -f /opt/docker/nginx-proxy-manager/docker-compose.yml restart
```

## Difference: `nginx_proxy` vs `deploy_compose`

| Feature | nginx_proxy | deploy_compose |
|---------|-------------|-----------------|
| Flexibility | Single app only | Multiple apps |
| Vault integration | No | Yes (passwords) |
| Permission setup | No | Yes (for Prometheus/Grafana) |
| Network creation | No | Yes (creates proxy-tier) |
| Use case | Standalone deployment | Full infrastructure |

**Recommendation:** Use `deploy_compose` for the main infrastructure. Use `nginx_proxy` only if you need a standalone Nginx Proxy Manager deployment.

## Next Steps

1. Ensure `docker_setup` role runs first
2. Add this role to your playbook
3. Run the playbook
4. Access the admin interface at port 81
5. Configure proxy rules for your applications

# Docker Setup Role

This role installs Docker Engine and containerd on your servers, making them ready to run containerized applications.

## What Does This Role Do?

### 1. Install Docker
- Adds Docker's official GPG key
- Adds Docker's official repository
- Installs Docker Engine, Docker CLI, and containerd
- Starts and enables Docker services

### 2. Configure User Permissions
- Adds the Ansible user to the `docker` group so it can run Docker commands without sudo

### 3. Verify Installation
- Runs `docker --version` to confirm Docker is working
- Displays the installed Docker version

## When Does This Run?

This role runs **after** `system_setup` on every server:
- `playbooks/docker.yml` (for Docker nodes)
- `playbooks/proxy.yml` (for Proxy nodes)

## Configuration

Edit `ansible/roles/docker_setup/defaults/main.yml` to customize:

```yaml
# Docker package versions (optional)
docker_packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
```

## What Gets Installed?

- **docker-ce** - Docker Community Edition
- **docker-ce-cli** - Docker command-line interface
- **containerd.io** - Container runtime

## Troubleshooting

### "E: Unable to locate package docker-ce"
The Docker repository wasn't added correctly. Check:
1. Is the server connected to the internet?
2. Is `apt update` working?
3. Try manually: `sudo apt update && sudo apt install -y docker-ce`

### "permission denied while trying to connect to Docker daemon"
The user wasn't added to the docker group. Try:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Docker service won't start
Check the logs:
```bash
sudo systemctl status docker
sudo journalctl -u docker -n 50
```

## Example Output

```
TASK [docker_setup : Install Docker Engine, CLI, and containerd]
changed: [Terra-debian-webserver]

TASK [docker_setup : Verify Docker installation]
ok: [Terra-debian-webserver]

TASK [docker_setup : Display Docker version]
Docker version 29.4.3, build 055a478
```

## Next Steps

After this role completes, the `deploy_compose` role deploys Docker Compose applications (Portainer, Monitoring, Nginx Proxy Manager).

## Manual Docker Commands

Once Docker is installed, you can use:

```bash
# Check Docker status
docker ps

# View Docker version
docker --version

# View Docker logs
docker logs <container-name>

# Stop a container
docker stop <container-name>
```

# DevContainer Configuration for T1-Small Topology

This directory contains the VS Code DevContainer configuration for running the SONiC T1-Small topology using Docker-outside-of-Docker (DooD).

## What is Docker-outside-of-Docker?

Docker-outside-of-Docker allows you to run Docker commands from inside a container while using the host's Docker daemon. This is ideal for:

- **Mac users** who want to run containerlab in a Linux environment
- **Consistent development environment** across different platforms
- **Easy setup** without installing containerlab directly on the host

## Prerequisites

1. **Docker Desktop** installed and running
2. **VS Code** with the "Dev Containers" extension installed
3. **Sufficient resources** allocated to Docker Desktop:
   - Memory: 8GB minimum (16GB recommended)
   - CPUs: 4 cores minimum
   - Disk: 20GB free space

## How to Use

### Method 1: Open in DevContainer (Recommended)

1. Open VS Code
2. Open the `sonic-mgmt-vs` folder
3. VS Code will detect the `.devcontainer` folder
4. Click "Reopen in Container" when prompted
   - Or use Command Palette (Cmd+Shift+P): "Dev Containers: Reopen in Container"
5. Wait for the container to build and start (first time takes 2-3 minutes)

### Method 2: Command Palette

1. Open VS Code
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. Type "Dev Containers: Open Folder in Container"
4. Select the `sonic-mgmt-vs` folder

## What's Included

The devcontainer provides:

- ✅ **Containerlab** pre-installed (version 0.69.0)
- ✅ **Docker CLI** connected to host Docker daemon
- ✅ **Python** for PTF and automation scripts
- ✅ **VS Code extensions** for YAML, Docker, Shell, Markdown
- ✅ **Git** for version control
- ✅ **Shell tools** (bash, zsh)

## Using the DevContainer

Once inside the devcontainer, you can run all commands as if you were on a Linux system:

### Deploy the Topology

```bash
cd topology
sudo clab deploy -t t1-small.clab.yml
```

### Configure BGP

```bash
cd scripts
./configure_bgp.sh
```

### Verify Topology

```bash
./verify_topology.sh
```

### Access Containers

```bash
docker exec -it clab-t1-small-sonic-dut bash
```

## DevContainer Features

### Automatic Setup

The devcontainer automatically:
- Mounts the Docker socket from the host
- Configures network access (host networking)
- Sets up privileged mode for containerlab
- Installs VS Code extensions

### Workspace Persistence

Your workspace files are mounted from the host, so:
- ✅ Changes persist after closing the devcontainer
- ✅ Git operations work normally
- ✅ Files are accessible from both host and container

### Terminal Integration

The integrated terminal in VS Code runs inside the devcontainer:
- Use `sudo clab` commands directly
- Access Docker containers on the host
- Run scripts and automation

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Solution:**
1. Ensure Docker Desktop is running on the host
2. Check Docker socket is accessible: `ls -la /var/run/docker.sock`
3. Restart the devcontainer

### Issue: "Permission denied" when running containerlab

**Solution:**
Use `sudo` with containerlab commands:
```bash
sudo clab deploy -t t1-small.clab.yml
```

### Issue: DevContainer fails to start

**Solution:**
1. Check Docker Desktop has sufficient resources
2. Try rebuilding the container:
   - Command Palette → "Dev Containers: Rebuild Container"
3. Check Docker Desktop logs for errors

### Issue: Slow performance on Mac

**Solution:**
1. Increase Docker Desktop resources (Memory, CPU)
2. Use `consistency=cached` for mounts (already configured)
3. Exclude `clab-*` directories from file watchers (already configured)

## Configuration Details

### Image

Uses the official containerlab devcontainer image:
```
ghcr.io/srl-labs/containerlab/devcontainer-dood-slim:0.69.0
```

### Mounts

The following host directories are mounted:
- `/var/run/docker.sock` - Docker daemon socket
- `/var/lib/docker` - Docker data directory
- `/run/docker/netns` - Docker network namespaces
- `/lib/modules` - Kernel modules
- `/etc/hosts` - Host file

### Privileges

The container runs with:
- `--privileged` - Required for containerlab networking
- `--network=host` - Access to host network
- `--pid=host` - Access to host process namespace

## VS Code Extensions

Pre-installed extensions:
- **Containerlab** - Syntax highlighting and validation
- **Docker** - Container management
- **Python** - PTF script development
- **YAML** - Configuration file editing
- **ShellCheck** - Shell script linting
- **Markdown** - Documentation editing

## Tips

1. **First Time Setup**: Allow 5 minutes for initial container build
2. **Resource Usage**: Monitor Docker Desktop resources
3. **Terminal**: Use the integrated terminal for all commands
4. **Git**: Works normally inside the devcontainer
5. **File Editing**: Edit files in VS Code, changes persist on host

## Alternative: Docker-in-Docker

If you prefer Docker-in-Docker instead of Docker-outside-of-Docker, you can modify the configuration to use a different base image. However, DooD is recommended for this use case.

## References

- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Containerlab DevContainer](https://containerlab.dev/manual/devcontainer/)
- [Docker-outside-of-Docker](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker)

## Support

For issues specific to:
- **DevContainer**: Check VS Code DevContainer documentation
- **Containerlab**: Check containerlab documentation
- **Topology**: See main README.md in project root


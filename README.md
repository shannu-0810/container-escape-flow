# Container Escape Flow

A controlled cybersecurity laboratory demonstrating how an intentionally exposed
Docker daemon socket can allow a container to interact with the Docker daemon
and create a container with access to a host-controlled directory.

This project is designed for an isolated VirtualBox college cybersecurity lab.

## Architecture

Kali Linux
    |
    | HTTP :5001
    v
APP01 - Ubuntu Server
    |
    +-- vulnerable container: escape-lab
    |       |
    |       +-- /var/run/docker.sock
    |               |
    |               v
    |          Docker daemon
    |
    +-- normal container: vulnerable-app
    |
    +-- /tmp/container-lab-proof
            |
            +-- escape.txt

## Lab IP

APP01:

    192.168.56.20

Host-only network:

    192.168.56.0/24

The lab should remain isolated from production or public networks.

## Requirements

- VirtualBox
- Ubuntu Server 24.04 or compatible Linux host
- Docker Engine
- Kali Linux or another testing VM
- Host-only network connectivity between Kali and APP01

## Deploy APP01

Clone the repository:

    git clone <YOUR-REPOSITORY-URL>
    cd container-escape-flow

Run:

    ./scripts/setup.sh

The script builds both Docker images and creates the two lab containers.

## Services

Normal application:

    http://192.168.56.20:5000

Intentionally vulnerable application:

    http://192.168.56.20:5001

Test from Kali:

    curl http://192.168.56.20:5000/
    curl http://192.168.56.20:5001/

## Vulnerability

The `escape-lab` container intentionally mounts:

    /var/run/docker.sock

This gives processes inside the container access to the Docker daemon.

Verify:

    sudo docker inspect escape-lab \
      --format 'DockerSocket={{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}'

Verify Docker daemon access:

    sudo docker exec escape-lab python -c \
    "import socket; s=socket.socket(socket.AF_UNIX); s.connect('/var/run/docker.sock'); print('Docker daemon accessible from container')"

## Controlled Proof

The project uses a harmless proof directory:

    /tmp/container-lab-proof

A helper Alpine container is created through the Docker daemon and mounts only
this proof directory.

The helper writes:

    /proof/escape.txt

The resulting host-side file is:

    /tmp/container-lab-proof/escape.txt

Expected content:

    Container escape successful

No sensitive host files are accessed.

## Evidence

### 1. Docker socket

    sudo docker inspect escape-lab \
      --format 'DockerSocket={{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}'

### 2. Docker daemon access

    sudo docker exec escape-lab python -c \
    "import socket; s=socket.socket(socket.AF_UNIX); s.connect('/var/run/docker.sock'); print('Docker daemon accessible from container')"

### 3. Host-side proof

    cat /tmp/container-lab-proof/escape.txt

Expected:

    Container escape successful

## Container Persistence

Both lab containers use:

    --restart unless-stopped

Therefore they automatically restart when Docker starts after a reboot.

Check:

    sudo docker inspect vulnerable-app escape-lab \
      --format '{{.Name}} -> {{.HostConfig.RestartPolicy.Name}}'

## Project Structure

    container-escape-flow/
    ├── README.md
    ├── app/
    │   └── app.py
    ├── docker/
    │   ├── Dockerfile
    │   └── vulnerable-Dockerfile
    ├── docs/
    │   └── attack-flow.md
    └── scripts/
        └── setup.sh

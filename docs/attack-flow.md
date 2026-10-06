# Container Escape Flow

## Objective

Demonstrate a controlled container escape scenario caused by exposing the
Docker Unix socket to a container.

This demonstration is intended only for an isolated, authorized laboratory.

## Attack Flow

Kali
  |
  | HTTP :5001
  v
APP01
  |
  v
escape-lab container
  |
  | /var/run/docker.sock
  v
Docker daemon
  |
  v
Helper Alpine container
  |
  | /tmp/container-lab-proof:/proof
  v
APP01 host
  |
  +-- /tmp/container-lab-proof/escape.txt

## Step 1 - Application Discovery

From Kali:

    curl http://192.168.56.20:5001/

Expected response:

    Internal Service Portal

## Step 2 - Identify Docker Socket Exposure

On APP01:

    sudo docker inspect escape-lab \
      --format 'DockerSocket={{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}'

Expected:

    DockerSocket=/var/run/docker.sock -> /var/run/docker.sock

## Step 3 - Confirm Docker Daemon Access

Run:

    sudo docker exec escape-lab python -c \
    "import socket; s=socket.socket(socket.AF_UNIX); s.connect('/var/run/docker.sock'); print('Docker daemon accessible from container')"

Expected:

    Docker daemon accessible from container

## Step 4 - Controlled Host-Impact Demonstration

A helper Alpine container is created through the Docker daemon API.

The helper container mounts only the controlled laboratory directory:

    /tmp/container-lab-proof:/proof

The helper creates:

    /proof/escape.txt

Because `/proof` maps to the APP01 host directory, the file becomes visible
on the host as:

    /tmp/container-lab-proof/escape.txt

## Step 5 - Verify the Proof

On APP01:

    cat /tmp/container-lab-proof/escape.txt

Expected:

    Container escape successful

## Evidence Checklist

- [ ] Application reachable from Kali
- [ ] Docker socket visible inside escape-lab
- [ ] Docker daemon accessible from escape-lab
- [ ] Helper container created
- [ ] Host-side proof file created
- [ ] Screenshots captured

## Security Impact

Access to the Docker daemon socket is highly sensitive.

A container with access to the Docker daemon may be able to control Docker
resources and potentially obtain access to host resources.

## Mitigation

- Do not expose `/var/run/docker.sock` to untrusted containers.
- Follow least-privilege container design.
- Use rootless/containerized Docker where appropriate.
- Consider a restricted Docker API proxy when socket access is required.
- Apply AppArmor or SELinux controls where appropriate.
- Segment container and management networks.
- Monitor container runtime activity.
- Regularly review container mounts and privileges.

## Lab Safety

This project intentionally introduces an insecure Docker configuration.

Do not deploy this vulnerable configuration on production systems,
internet-facing systems, or networks containing sensitive information.

Use only inside an authorized and isolated laboratory environment.

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




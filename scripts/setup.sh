#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "[+] Checking Docker..."
sudo systemctl enable --now docker

echo "[+] Building normal application image..."
sudo docker build -f docker/Dockerfile -t container-lab-app .

echo "[+] Building vulnerable application image..."
sudo docker build -f docker/vulnerable-Dockerfile -t container-lab-vulnerable .

echo "[+] Creating proof directory..."
sudo mkdir -p /tmp/container-lab-proof
sudo chmod 777 /tmp/container-lab-proof

echo "[+] Creating vulnerable-app container if required..."
if ! sudo docker container inspect vulnerable-app >/dev/null 2>&1; then
    sudo docker run -d \
        --name vulnerable-app \
        --restart unless-stopped \
        -p 5000:5000 \
        container-lab-app
else
    sudo docker update --restart unless-stopped vulnerable-app >/dev/null
    sudo docker start vulnerable-app >/dev/null 2>&1 || true
fi

echo "[+] Creating intentionally vulnerable escape-lab container if required..."
if ! sudo docker container inspect escape-lab >/dev/null 2>&1; then
    sudo docker run -d \
        --name escape-lab \
        --restart unless-stopped \
        -p 5001:5000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        container-lab-vulnerable
else
    sudo docker update --restart unless-stopped escape-lab >/dev/null
    sudo docker start escape-lab >/dev/null 2>&1 || true
fi

echo
echo "[+] Lab status:"
sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"

echo
echo "[+] Container socket verification:"
sudo docker exec escape-lab ls -l /var/run/docker.sock

echo
echo "[+] Docker daemon connectivity:"
sudo docker exec escape-lab python -c \
'import socket; s=socket.socket(socket.AF_UNIX); s.connect("/var/run/docker.sock"); print("Docker daemon accessible from container")'

echo
echo "[+] APP01 container lab is ready."
echo "[+] Normal application : http://APP01:5000"
echo "[+] Vulnerable lab      : http://APP01:5001"

#!/bin/bash

# Docker Installation Script for Ubuntu 24.04
# This script installs Docker and configures it to run without sudo

set -e

echo "=== Docker Installation Script ==="
echo "Starting Docker installation on Ubuntu 24.04..."
echo ""

# Update package index
echo "Updating package index..."
sudo apt update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "Updating package index with Docker repository..."
sudo apt update

# Install Docker Engine, CLI, and containerd
echo "Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create the docker group (if it doesn't exist)
echo "Creating docker group..."
sudo groupadd docker 2>/dev/null || true

# Add current user to the docker group
echo "Adding user '$USER' to docker group..."
sudo usermod -aG docker $USER

# Start and enable Docker service
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "=== Installation Complete ==="
echo "Docker has been successfully installed!"
echo ""
echo "IMPORTANT: To run Docker without sudo, you need to:"
echo "1. Log out and log back in, OR"
echo "2. Run: newgrp docker (applies changes to current terminal only)"
echo ""
echo "After that, test with: docker run hello-world"
echo ""
echo "Docker version:"
docker --version
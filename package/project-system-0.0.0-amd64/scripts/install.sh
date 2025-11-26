#!/bin/bash

#TODO: implement remote install logic

# LOGFILE="/tmp/install_main.log"
# exec > >(tee -a "$LOGFILE") 2>&1

# echo "[MAIN] Starting Main installation at $(date)"

# REPO_PATH="/tmp/local-repo"
# SOURCE_FILE="/etc/apt/sources.list.d/local-offline.list"

# echo "[MAIN] Preparing local repo at $REPO_PATH"
# sudo rm -rf "$REPO_PATH"
# sudo mkdir -p "$REPO_PATH"
# sudo cp -r "$(dirname "$0")/../local-repo/"* "$REPO_PATH/"

# echo "[MAIN] Writing local APT source..."
# echo "deb [trusted=yes] file:$REPO_PATH ./" | sudo tee "$SOURCE_FILE" >/dev/null

# echo "[MAIN] Running apt-get update..."
# sudo apt-get update

# echo "[MAIN] Installing system-services meta-package..."
# sudo DEBIAN_FRONTEND=noninteractive apt-get install -y system-services

# echo "[MAIN] Main installation completed successfully at $(date)"

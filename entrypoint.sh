#!/bin/bash

set -e

# This script runs as root to fix permissions, then drops to steam user

CLUSTER_DIR="/home/steam/.klei/DoNotStarveTogether/MyDediServer"

echo "=== Fixing volume permissions ==="

# Get the steam user's UID and GID
STEAM_UID=$(id -u steam)
STEAM_GID=$(id -g steam)

echo "Steam user: uid=${STEAM_UID} gid=${STEAM_GID}"

# Create cluster directory if it doesn't exist
if [ ! -d "${CLUSTER_DIR}" ]; then
    mkdir -p "${CLUSTER_DIR}"
fi

# Fix ownership of the cluster directory
echo "Fixing ownership of ${CLUSTER_DIR}..."
chown -R steam:steam "${CLUSTER_DIR}"

# Ensure steam user can write to the directory
chmod -R u+w "${CLUSTER_DIR}"

echo "Permissions fixed successfully!"
echo ""

# Drop to steam user and run the actual startup script
exec su -s /bin/bash steam -c "/home/steam/start_server.sh"

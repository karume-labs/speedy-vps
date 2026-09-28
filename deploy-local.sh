#!/bin/bash
set -e

# ==============================================================================
# Local Deployment Script (CI/CD Bypass)
# ==============================================================================
# This script builds your application's Docker image locally, pushes it to your
# container registry, and then triggers Ansible to pull and restart the app on
# your VPS.
# ==============================================================================

# Load from .env if it exists (optional, for convenience)
if [ -f ".env.deploy" ]; then
    source .env.deploy
fi

# Auto-discover app name from Ansible group_vars
APP_NAME=$(grep '^app_name:' group_vars/all.yml | sed 's/^app_name:[[:space:]]*//' | tr -d '"'\''' || echo "example-app")

# 1. Setup APP_DIR (Check env var -> Prompt -> Default)
if [ -z "$APP_DIR" ]; then
    DEFAULT_APP_DIR="../$APP_NAME"
    read -p "Enter path to application source code [$DEFAULT_APP_DIR]: " USER_APP_DIR
    APP_DIR=${USER_APP_DIR:-$DEFAULT_APP_DIR}
fi

# 2. Setup IMAGE_NAME (Check env var -> Prompt -> Default)
if [ -z "$IMAGE_NAME" ]; then
    DEFAULT_IMAGE_NAME="ghcr.io/your_org/${APP_NAME}:latest"
    read -p "Enter Docker registry image name [$DEFAULT_IMAGE_NAME]: " USER_IMAGE_NAME
    IMAGE_NAME=${USER_IMAGE_NAME:-$DEFAULT_IMAGE_NAME}
fi

echo "==================================="
echo "Starting Local Deployment..."
echo "==================================="

# 1. Build the Docker image locally
echo "[1/3] Building Docker image ($IMAGE_NAME)..."
if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory '$APP_DIR' not found."
    echo "Please update the APP_DIR variable in this script."
    exit 1
fi

# Run docker build in the application directory
docker build -t "$IMAGE_NAME" "$APP_DIR"

# 2. Push to the registry
echo "[2/3] Pushing Docker image to registry..."
docker push "$IMAGE_NAME"

# 3. Update the server using Ansible
echo "[3/3] Triggering server update via Ansible..."
# This runs the 'setup-app' target in your Makefile
make setup-app

echo "==================================="
echo "Deployment complete!"
echo "==================================="

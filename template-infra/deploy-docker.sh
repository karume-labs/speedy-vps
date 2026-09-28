#!/bin/bash
set -e

# NOTE: Copy this file out of `infra/` and into your app's root folder!
# Configure these variables for your specific application
APP_NAME="my-awesome-app"
SERVER_ALIAS="my-app-server"
IMAGE_NAME="ghcr.io/your-username/my-awesome-app:latest" # Change to your actual registry

echo "Starting Docker deployment of $APP_NAME..."

# 1. Build and push your Docker Image (Uncomment if doing it locally)
# echo "Building and pushing Docker image..."
# docker build -t "$IMAGE_NAME" .
# docker push "$IMAGE_NAME"

# 2. Trigger pull and restart on the VPS
echo "Pulling new image and restarting Docker Compose stack on VPS..."
ssh "$SERVER_ALIAS" << EOF
set -e
cd /opt/apps/$APP_NAME
# If using a private registry, run 'docker login' here first
docker compose pull
docker compose up -d --remove-orphans
EOF

echo "Deployment complete! $APP_NAME is now live."

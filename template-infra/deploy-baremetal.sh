#!/bin/bash
set -e

# NOTE: Copy this file out of `infra/` and into your app's root folder!
# Configure these variables for your specific application
APP_NAME="my-awesome-app"
SERVER_ALIAS="my-app-server"
DB_URL="postgres://user:pass@127.0.0.1:5432/db"

echo "Starting deployment of $APP_NAME..."

# 1. Sync code to VPS
echo "Syncing files to VPS..."
rsync -avz --exclude node_modules --exclude .next --exclude .git ./ "$SERVER_ALIAS:/opt/apps/$APP_NAME/"

# 2. Setup environment variables securely over SSH
echo "Configuring environment variables..."
ssh "$SERVER_ALIAS" "echo 'DATABASE_URL=\"$DB_URL\"' > /opt/apps/$APP_NAME/.env.local"

# 3. Install, Build, and Start PM2 Process (Next.js SSR example)
echo "Building and restarting PM2 process..."
ssh "$SERVER_ALIAS" << EOF
set -e
export LEFTHOOK=0
export CI=1
cd /opt/apps/$APP_NAME
bun install --ignore-scripts
bun run build
pm2 delete "$APP_NAME" || true
# Use the following for Next.js Static Export:
# pm2 start "npx serve@latest out -p 3000" --name '$APP_NAME'
# Use the following for standard Next.js:
pm2 start bun --name '$APP_NAME' -- run start
pm2 save
pm2 startup
EOF

echo "Deployment complete! $APP_NAME is now live."

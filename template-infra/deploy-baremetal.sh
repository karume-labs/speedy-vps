#!/bin/bash
set -e

# NOTE: Copy this file out of `infra/` and into your app's root folder!
# Configure these variables for your specific application
APP_NAME="my-awesome-app"
SERVER_ALIAS="my-app-server"

echo "Starting deployment of $APP_NAME..."

# 1. Sync code to VPS
echo "Syncing files to VPS..."
rsync -avz --exclude node_modules --exclude .next --exclude .git --exclude .env.local ./ "$SERVER_ALIAS:/opt/apps/$APP_NAME/"

# (Environment variables are automatically injected by Ansible during setup-all)

# 3. Install, Build, and Start PM2 Process (Next.js SSR example)
echo "Building and restarting PM2 process..."
ssh "$SERVER_ALIAS" << EOF
set -e
export LEFTHOOK=0
export CI=1
cd /opt/apps/$APP_NAME
bun install --ignore-scripts
bun run build
# Use the following for Next.js Static Export (output: export):
pm2 restart $APP_NAME 2>/dev/null || pm2 start "bunx serve@latest out -p 3000" --name '$APP_NAME'
# Use the following for standard Next.js SSR (uncomment and replace above):
# pm2 restart $APP_NAME 2>/dev/null || pm2 start bun --name '$APP_NAME' -- run start
pm2 save
EOF

echo "Deployment complete! $APP_NAME is now live."

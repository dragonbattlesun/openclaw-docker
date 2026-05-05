#!/bin/bash
set -e

cd "$(dirname "$0")"

# 使用 T7 上的 .env
export $(grep -v '^#' .env | xargs)

echo "Starting openclaw gateway (T7)..."
docker compose up -d openclaw-gateway

# Feishu plugin deps
FEISHU_PLUGIN_DIR="${OPENCLAW_CONFIG_DIR}/extensions-npm/node_modules/@openclaw/feishu"
if [ -f "$FEISHU_PLUGIN_DIR/package.json" ] && [ ! -d "$FEISHU_PLUGIN_DIR/node_modules" ]; then
  echo "Installing Feishu plugin dependencies..."
  docker exec openclaw-openclaw-gateway-1 sh -c "cd /home/node/.openclaw/extensions-npm/node_modules/@openclaw/feishu && npm install --omit=dev" 2>/dev/null || true
fi

echo "Waiting for gateway to be ready..."
for i in $(seq 1 15); do
  if curl -s --max-time 1 http://127.0.0.1:${OPENCLAW_GATEWAY_PORT} > /dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "Opening browser..."
open "http://127.0.0.1:${OPENCLAW_GATEWAY_PORT}?token=${OPENCLAW_GATEWAY_TOKEN}"

echo "Done. Gateway running at http://127.0.0.1:${OPENCLAW_GATEWAY_PORT}"

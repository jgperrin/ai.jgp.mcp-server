#!/bin/bash
# Resilient MCP bridge — auto-restarts mcp-remote when the server disconnects.
# Claude Desktop spawns this script via stdio; it manages mcp-remote lifecycle.

MCP_URL="${1:-https://api.jgp.ai/mcp}"
MAX_RETRIES=100
RETRY_DELAY=3

retry=0
while [ $retry -lt $MAX_RETRIES ]; do
  npx mcp-remote "$MCP_URL" 2>/dev/null
  exit_code=$?

  # If mcp-remote exited cleanly (user quit Claude Desktop), stop
  if [ $exit_code -eq 0 ]; then
    break
  fi

  retry=$((retry + 1))
  echo "mcp-remote exited ($exit_code), reconnecting in ${RETRY_DELAY}s (attempt $retry/$MAX_RETRIES)..." >&2
  sleep $RETRY_DELAY
done

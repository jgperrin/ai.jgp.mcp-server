#!/bin/bash
# ============================================================================
# Data Product Workbench — MCP Server Installer for macOS
# Version: 1.0.1
#
# Configures Claude Desktop to connect to the Workbench MCP server.
#
# Usage:
#   curl -fsSL https://workbench.actianlabs.com/install-mcp.sh | bash
#   — or —
#   bash install-mcp.sh
# ============================================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────

MCP_KEY="data-product-workbench"
MCP_URL="https://api.jgp.ai/mcp"
CLAUDE_APP="/Applications/Claude.app"
CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

# ── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo "  ✓ $1"; }
warn()    { echo "  ⚠ $1"; }
err()     { echo "  ✗ $1"; }
step()    { echo ""; echo "▸ $1"; }

dialog_ok() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Data Product Workbench\" with icon note" > /dev/null 2>&1 || true
}

dialog_error() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Data Product Workbench\" with icon stop" > /dev/null 2>&1 || true
}

dialog_success() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Data Product Workbench\" with icon note" > /dev/null 2>&1 || true
}

# ── JSON manipulation via Python 3 (built into macOS) ────────────────────────

update_config() {
  python3 << 'PYEOF'
import json, sys, os

config_file = os.path.expanduser("~/Library/Application Support/Claude/claude_desktop_config.json")
mcp_key = "data-product-workbench"
mcp_url = "https://api.jgp.ai/mcp"

# Read existing config or start fresh
config = {}
if os.path.exists(config_file):
    try:
        with open(config_file, 'r') as f:
            content = f.read().strip()
            if content:
                config = json.loads(content)
    except (json.JSONDecodeError, IOError) as e:
        # Backup corrupt file
        backup = config_file + ".backup"
        os.rename(config_file, backup)
        print(f"BACKED_UP:{backup}")
        config = {}

# Ensure mcpServers exists
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Check current state
servers = config["mcpServers"]
if mcp_key in servers:
    current = servers[mcp_key]
    if isinstance(current, dict) and current.get("command") == "npx" and \
       isinstance(current.get("args"), list) and mcp_url in current.get("args", []) and \
       "--transport" in current.get("args", []):
        print("ALREADY_OK")
        sys.exit(0)
    else:
        print("UPDATED")
else:
    print("ADDED")

# Set the config
servers[mcp_key] = {
    "command": "npx",
    "args": ["mcp-remote", mcp_url, "--transport", "sse-only"]
}

# Write config
os.makedirs(os.path.dirname(config_file), exist_ok=True)
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

PYEOF
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo ""
echo ""
echo "  Data Product Workbench - MCP Server Installer v1.0.1"
echo "  ────────────────────────────────────────────────────"

# Step 1: Check Claude Desktop
step "Checking Claude Desktop..."
if [ ! -d "$CLAUDE_APP" ]; then
  err "Claude Desktop is not installed."
  echo ""
  echo "  Download it from: https://claude.ai/download"
  echo ""
  dialog_error "Claude Desktop is not installed.\n\nDownload it from:\nhttps://claude.ai/download"
  exit 1
fi
info "Claude Desktop found."

# Step 1b: Check Node.js (required for npx / mcp-remote)
step "Checking Node.js..."
if ! command -v npx &> /dev/null; then
  err "Node.js is not installed (npx is required)."
  echo ""
  echo "  Install it from: https://nodejs.org"
  echo ""
  dialog_error "Node.js is not installed.\nnpx is required to bridge Claude Desktop to the MCP server.\n\nInstall from: https://nodejs.org"
  exit 1
fi
info "Node.js found (npx available)."

# Step 2: Check Python 3
step "Checking Python 3..."
if ! command -v python3 &> /dev/null; then
  err "Python 3 is not available (required for JSON handling)."
  dialog_error "Python 3 is not available on this Mac.\nPlease install Xcode Command Line Tools:\n\nxcode-select --install"
  exit 1
fi
info "Python 3 available."

# Step 3: Update config
step "Configuring MCP server..."
RESULT=$(update_config)

if echo "$RESULT" | grep -q "BACKED_UP"; then
  BACKUP=$(echo "$RESULT" | grep "BACKED_UP:" | cut -d: -f2-)
  warn "Existing config was corrupt — backed up to:"
  echo "    $BACKUP"
  RESULT=$(echo "$RESULT" | grep -v "BACKED_UP")
fi

case "$RESULT" in
  ALREADY_OK)
    info "Already configured correctly — nothing to change."
    ;;
  UPDATED)
    info "Configuration updated."
    ;;
  ADDED)
    info "MCP server added to Claude Desktop config."
    ;;
  *)
    err "Unexpected result: $RESULT"
    dialog_error "Configuration failed. Please try manual setup:\nhttps://workbench.actianlabs.com/help/mcp-setup"
    exit 1
    ;;
esac

# Step 4: Show current config
step "Configuration:"
echo "    File: $CONFIG_FILE"
echo "    Server: $MCP_KEY"
echo "    URL: $MCP_URL"

# Step 5: Test connectivity
step "Testing MCP server connectivity..."
if curl -s --max-time 5 "$MCP_URL" 2>/dev/null | head -1 | grep -q "^id:"; then
  info "MCP server is reachable."
else
  warn "Could not reach the MCP server (it may be temporarily down)."
  echo "    This won't prevent configuration — you can test later."
fi

# Step 6: Restart Claude Desktop
step "Restarting Claude Desktop..."
CLAUDE_WAS_RUNNING=false
if pgrep -x "Claude" > /dev/null 2>&1; then
  CLAUDE_WAS_RUNNING=true
  osascript -e 'tell application "Claude" to quit' > /dev/null 2>&1 || true
  sleep 2
fi

if [ "$CLAUDE_WAS_RUNNING" = true ]; then
  open "$CLAUDE_APP"
  sleep 2
  info "Claude Desktop restarted."
else
  info "Claude Desktop was not running — it will pick up the config on next launch."
fi

# Done
echo ""
echo "  ────────────────────────────────────────────────────"
echo ""
echo "  All done!"
echo ""
echo "  Open Claude Desktop and say:"
echo "  \"Log in to the Workbench\""
echo ""
echo ""

if [ "$RESULT" = "ALREADY_OK" ]; then
  dialog_success "Data Product Workbench is already configured in Claude Desktop.\n\nOpen Claude and say:\n\"Log in to the Workbench\""
else
  dialog_success "Data Product Workbench has been configured!\n\nOpen Claude Desktop and say:\n\"Log in to the Workbench\""
fi

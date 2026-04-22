# Data Product Workbench - MCP Server Installer

macOS installer for connecting [Claude Desktop](https://claude.ai/download) to the [Data Product Workbench](https://workbench.actianlabs.com) MCP server.

## Quick Install

[Download the installer](https://workbench.actianlabs.com/macos-installer), then run:

```bash
bash ~/Downloads/install-mcp.sh
```

## What It Does

The installer:

1. Checks that Claude Desktop and Node.js are installed
2. Adds the Workbench MCP server to Claude Desktop's config (`claude_desktop_config.json`)
3. Preserves any existing MCP servers in the config
4. Tests connectivity to the MCP server
5. Restarts Claude Desktop
6. Shows native macOS dialogs for feedback

If already configured correctly, it's a no-op.

## Prerequisites

- macOS
- [Claude Desktop](https://claude.ai/download)
- [Node.js](https://nodejs.org) (for `npx`)

## How It Works

Claude Desktop connects to the Workbench MCP server via [mcp-remote](https://www.npmjs.com/package/mcp-remote), a bridge that translates between stdio (Claude Desktop) and SSE (the remote server):

```
Claude Desktop <--stdio--> mcp-remote <--SSE--> api.jgp.ai/mcp
```

The installer writes this config to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "data-product-workbench": {
      "command": "npx",
      "args": ["mcp-remote", "https://api.jgp.ai/mcp", "--transport", "sse-only"]
    }
  }
}
```

## After Installation

Open Claude Desktop and say **"Log in to the Workbench"**. Claude will display a code to enter at `app.bitol.io/link` to authorize the connection.

## Manual Setup

See the [MCP Server Setup Guide](https://workbench.actianlabs.com/help/mcp-setup) for step-by-step manual instructions.

## Deployment

The installer is served from `https://workbench.actianlabs.com/install-mcp.sh`. To deploy a new version:

1. Update `install-mcp.sh` in this repo
2. Copy to the webapp's public directory: `cp install-mcp.sh ../ai.jgp.workbench.webapp/public/`
3. Commit and push both repos

## Related Projects

| Project | Description |
|---------|-------------|
| [ai.jgp.bitol.svc](https://github.com/jgperrin/ai.jgp.bitol.svc) | Bitol REST API (device code auth endpoints) |
| [ai.jgp.bitol.mcp](https://github.com/jgperrin/ai.jgp.bitol.mcp) | MCP server (Spring Boot, SSE transport) |
| [ai.jgp.workbench.webapp](https://github.com/jgperrin/ai.jgp.workbench.webapp) | Web app (hosts installer, help docs, /link page) |

## License

Apache License 2.0

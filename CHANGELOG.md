# Changelog

## v1.0.6 - 2026-04-23

### Added
- `mcp-bridge.sh` — auto-reconnecting wrapper around mcp-remote. Restarts mcp-remote when server disconnects.
- Installer downloads bridge to `~/.workbench/mcp-bridge.sh` and configures Claude Desktop to use it.

## v1.0.5 - 2026-04-23

### Changed
- Switch to Streamable HTTP transport — remove `--transport sse-only` flag and `/mcp/sse` path.
- MCP URL simplified to `https://api.jgp.ai/mcp`.

## v1.0.4 - 2026-04-22

### Changed
- MCP server URL updated to `/mcp/sse` (explicit SSE endpoint path).

## v1.0.3 - 2026-04-22

### Fixed
- Connectivity test checks HTTP status code (200/302) instead of parsing SSE stream.
- Redirect stdin for inner curl to avoid pipe conflict when installed via `curl | bash`.

## v1.0.2 - 2026-04-22

### Fixed
- Connectivity test now follows redirects and uses trailing slash to avoid 302 protocol downgrade.

## v1.0.1 - 2026-04-22

### Fixed
- Added `--transport sse-only` flag to mcp-remote config (without it, mcp-remote hangs on OAuth discovery).
- ALREADY_OK check now also verifies `--transport` flag is present, so existing configs without it get updated.

### Changed
- Bottom separator line length matches header.


## v1.0.0 - 2026-04-22

### Added
- Initial release of the macOS installer.
- Configures Claude Desktop to connect to the Workbench MCP server via `npx mcp-remote`.
- Checks for Claude Desktop, Node.js, and Python 3.
- Preserves existing MCP servers in `claude_desktop_config.json`.
- Handles corrupt config files (backs up and recreates).
- Detects if already correctly configured (no-op).
- Tests SSE connectivity to `api.jgp.ai/mcp`.
- Restarts Claude Desktop automatically.
- Native macOS dialogs via `osascript`.

#!/usr/bin/env bash
#
# setup-mcp.sh — Register XcodeBuildMCP for Claude Code and Codex.
#
# What this does:
#   1. Checks prerequisites (Xcode command-line tools, Node.js / npx).
#   2. Registers the XcodeBuildMCP server with Claude Code (if installed).
#   3. Registers the XcodeBuildMCP server with Codex (if installed).
#   4. Prints how to verify everything is connected.
#
# Usage:
#   cd into this folder, then:   bash setup-mcp.sh
#
# Safe to re-run. It won't duplicate anything.

set -u

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "1. Checking prerequisites"

# --- Xcode command-line tools ---
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode command-line tools found at: $(xcode-select -p)"
else
  err "Xcode command-line tools not found."
  echo "    Run:  xcode-select --install"
  echo "    Then re-run this script."
  exit 1
fi

if command -v xcodebuild >/dev/null 2>&1; then
  ok "xcodebuild: $(xcodebuild -version | head -n1)"
else
  warn "xcodebuild not on PATH. If builds fail later, run:"
  echo "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

# --- Node.js / npx (needed to run the MCP server) ---
if command -v node >/dev/null 2>&1 && command -v npx >/dev/null 2>&1; then
  NODE_MAJOR="$(node -v | sed 's/v\([0-9]*\).*/\1/')"
  if [ "${NODE_MAJOR:-0}" -ge 18 ]; then
    ok "Node.js $(node -v) (npx available)"
  else
    err "Node.js $(node -v) is too old. XcodeBuildMCP needs Node 18+."
    echo "    Upgrade with:  brew install node   (or use nvm)"
    exit 1
  fi
else
  err "Node.js / npx not found. Install it first:"
  echo "    brew install node     (Homebrew)"
  echo "    or download from https://nodejs.org"
  exit 1
fi

echo

# --- Helper to register the server with a given CLI ---
register() {
  local cli="$1"          # "claude" or "codex"
  local label="$2"        # human-readable name

  if ! command -v "$cli" >/dev/null 2>&1; then
    warn "$label CLI ('$cli') not found on PATH — skipping."
    echo "      Install it, then re-run this script to add the server."
    return
  fi

  bold "Registering XcodeBuildMCP with $label"

  # Skip if it already appears in the list.
  if "$cli" mcp list 2>/dev/null | grep -qi "XcodeBuildMCP"; then
    ok "Already registered with $label — nothing to do."
    return
  fi

  if "$cli" mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp; then
    ok "Added XcodeBuildMCP to $label."
  else
    err "Could not add the server to $label automatically."
    echo "      Add it manually with:"
    echo "      $cli mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp"
  fi
  echo
}

bold "2. Registering the MCP server"
echo
register claude "Claude Code"
register codex  "Codex"

bold "3. Verify"
echo "Run these to confirm the server shows as connected:"
echo "    claude mcp list"
echo "    codex mcp list"
echo
echo "Then, from inside your project folder, ask the agent something like:"
echo '    "build the InventionParty scheme for an iPhone simulator and launch it"'
echo
ok "Done."

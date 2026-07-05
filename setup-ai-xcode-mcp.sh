#!/usr/bin/env bash
#
# setup-ai-xcode-mcp.sh
#
# Sets up XcodeBuildMCP for Codex and Claude Code so both assistants can
# inspect, build, test, and launch your Xcode project through MCP.
#
# Usage:
#   cd "/Users/sawyerroberts/Downloads/InventionParty-Swift"
#   bash setup-ai-xcode-mcp.sh

set -u

SERVER_NAME="XcodeBuildMCP"
SERVER_COMMAND=(npx -y xcodebuildmcp@latest mcp)

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_hint_claude() {
  cat <<'EOF'

Claude Code is not installed or is not on your PATH.

Install it with one of these:

  brew install --cask claude-code

or:

  curl -fsSL https://claude.ai/install.sh | bash

After installing, run:

  claude

Sign in, then re-run this script.
EOF
}

check_prereqs() {
  bold "1. Checking Xcode"

  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode developer directory: $(xcode-select -p)"
  else
    err "Xcode command-line tools are missing."
    echo "    Run: xcode-select --install"
    exit 1
  fi

  if has_cmd xcodebuild; then
    ok "$(xcodebuild -version | head -n1)"
  else
    err "xcodebuild is not on PATH."
    echo "    Try: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
  fi

  echo
  bold "2. Checking Node.js"

  if has_cmd node && has_cmd npx; then
    node_major="$(node -v | sed 's/v\([0-9]*\).*/\1/')"
    if [ "${node_major:-0}" -ge 18 ]; then
      ok "Node $(node -v), npx $(npx -v)"
    else
      err "Node $(node -v) is too old. Install Node 18 or newer."
      echo "    Try: brew install node"
      exit 1
    fi
  else
    err "Node.js or npx is missing."
    echo "    Try: brew install node"
    exit 1
  fi
}

register_mcp() {
  local cli="$1"
  local label="$2"

  echo
  bold "Registering $SERVER_NAME with $label"

  if ! has_cmd "$cli"; then
    warn "$label CLI was not found."
    if [ "$cli" = "claude" ]; then
      install_hint_claude
    else
      echo "    Install or repair $label, then re-run this script."
    fi
    return 0
  fi

  if "$cli" mcp list 2>/dev/null | grep -qi "$SERVER_NAME"; then
    ok "$SERVER_NAME is already registered with $label."
    return 0
  fi

  if "$cli" mcp add "$SERVER_NAME" -- "${SERVER_COMMAND[@]}"; then
    ok "Added $SERVER_NAME to $label."
  else
    err "Could not automatically add $SERVER_NAME to $label."
    echo "    Run this manually:"
    printf "    %s mcp add %s --" "$cli" "$SERVER_NAME"
    printf " %q" "${SERVER_COMMAND[@]}"
    printf "\n"
  fi
}

verify_mcp() {
  local cli="$1"
  local label="$2"

  if ! has_cmd "$cli"; then
    return 0
  fi

  echo
  bold "Verifying $label MCP servers"
  "$cli" mcp list || warn "Could not list MCP servers for $label."
}

main() {
  bold "Xcode MCP setup for Codex and Claude Code"
  echo

  check_prereqs

  echo
  bold "3. Registering MCP servers"
  register_mcp codex "Codex"
  register_mcp claude "Claude Code"

  echo
  bold "4. Verification"
  verify_mcp codex "Codex"
  verify_mcp claude "Claude Code"

  echo
  bold "Done"
  echo "Restart Codex and Claude Code, then ask:"
  echo '  "Use XcodeBuildMCP to inspect this project, list schemes, and build it for an iPhone simulator."'
}

main "$@"

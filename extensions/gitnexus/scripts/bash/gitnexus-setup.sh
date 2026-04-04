#!/usr/bin/env bash
# GitNexus Setup Helper Script
#
# Usage:
#   gitnexus-setup.sh --check     Check if GitNexus CLI is installed
#   gitnexus-setup.sh --verify    Verify full setup state (CLI + MCP + index)
#   gitnexus-setup.sh --json      Output in JSON format (combine with --check or --verify)
#
# Exit codes:
#   0  All checks passed
#   1  GitNexus CLI not found
#   2  Partial setup (CLI found but MCP or index missing)

set -e

JSON_MODE=false
ACTION=""

for arg in "$@"; do
    case "$arg" in
        --check)  ACTION="check" ;;
        --verify) ACTION="verify" ;;
        --json)   JSON_MODE=true ;;
        --help|-h)
            echo "Usage: gitnexus-setup.sh [--check|--verify] [--json]"
            echo "  --check   Check if GitNexus CLI is installed"
            echo "  --verify  Verify full setup state"
            echo "  --json    Output in JSON format"
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option '$arg'. Use --help for usage." >&2
            exit 1
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    echo "ERROR: Specify --check or --verify. Use --help for usage." >&2
    exit 1
fi

# --- Helper functions ---

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g'
}

check_cli() {
    if command -v gitnexus >/dev/null 2>&1; then
        GITNEXUS_VERSION=$(gitnexus --version 2>/dev/null || echo "unknown")
        echo "installed"
        return 0
    elif npx -y gitnexus@latest --version >/dev/null 2>&1; then
        GITNEXUS_VERSION=$(npx -y gitnexus@latest --version 2>/dev/null || echo "unknown")
        echo "available-via-npx"
        return 0
    else
        echo "not-found"
        return 1
    fi
}

check_mcp_config() {
    # Check user-level mcp.json first (recommended for GitNexus global setup)
    local user_mcp_file=""
    case "$(uname -s)" in
        Darwin) user_mcp_file="$HOME/Library/Application Support/Code/User/mcp.json" ;;
        *)      user_mcp_file="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/mcp.json" ;;
    esac

    if [ -f "$user_mcp_file" ]; then
        if grep -q '"gitnexus"' "$user_mcp_file" 2>/dev/null; then
            echo "configured"
            return 0
        fi
    fi

    # Fall back to workspace-level .vscode/mcp.json
    local workspace_root
    workspace_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local mcp_file="$workspace_root/.vscode/mcp.json"

    if [ -f "$mcp_file" ]; then
        if grep -q '"gitnexus"' "$mcp_file" 2>/dev/null; then
            echo "configured"
            return 0
        else
            echo "missing-gitnexus-entry"
            return 1
        fi
    else
        echo "no-mcp-file"
        return 1
    fi
}

check_index() {
    local workspace_root
    workspace_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local meta_file="$workspace_root/.gitnexus/meta.json"

    if [ -f "$meta_file" ]; then
        echo "indexed"
        return 0
    else
        echo "not-indexed"
        return 1
    fi
}

# --- Actions ---

if [ "$ACTION" = "check" ]; then
    CLI_STATUS=$(check_cli) || true

    if $JSON_MODE; then
        printf '{"cli_status":"%s","version":"%s"}\n' \
            "$(json_escape "$CLI_STATUS")" \
            "$(json_escape "${GITNEXUS_VERSION:-}")"
    else
        echo "GitNexus CLI: $CLI_STATUS"
        if [ -n "${GITNEXUS_VERSION:-}" ]; then
            echo "Version: $GITNEXUS_VERSION"
        fi
    fi

    if [ "$CLI_STATUS" = "not-found" ]; then
        exit 1
    fi
    exit 0
fi

if [ "$ACTION" = "verify" ]; then
    CLI_STATUS=$(check_cli) || true
    MCP_STATUS=$(check_mcp_config) || true
    INDEX_STATUS=$(check_index) || true

    ALL_OK=true
    [ "$CLI_STATUS" = "not-found" ] && ALL_OK=false
    [ "$MCP_STATUS" != "configured" ] && ALL_OK=false
    [ "$INDEX_STATUS" != "indexed" ] && ALL_OK=false

    if $JSON_MODE; then
        printf '{"cli_status":"%s","version":"%s","mcp_status":"%s","index_status":"%s","all_ok":%s}\n' \
            "$(json_escape "$CLI_STATUS")" \
            "$(json_escape "${GITNEXUS_VERSION:-}")" \
            "$(json_escape "$MCP_STATUS")" \
            "$(json_escape "$INDEX_STATUS")" \
            "$( $ALL_OK && echo 'true' || echo 'false' )"
    else
        echo "GitNexus CLI: $CLI_STATUS"
        [ -n "${GITNEXUS_VERSION:-}" ] && echo "Version: $GITNEXUS_VERSION"
        echo "MCP Config: $MCP_STATUS"
        echo "Index: $INDEX_STATUS"
        echo ""
        if $ALL_OK; then
            echo "✅ All checks passed"
        else
            echo "⚠️  Some checks failed — run /speckit.gitnexus.setup to fix"
        fi
    fi

    if [ "$CLI_STATUS" = "not-found" ]; then
        exit 1
    fi
    $ALL_OK || exit 2
    exit 0
fi

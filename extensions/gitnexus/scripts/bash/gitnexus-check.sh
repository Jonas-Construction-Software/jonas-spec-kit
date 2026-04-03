#!/usr/bin/env bash
# GitNexus Runtime Guard
#
# Fast, non-blocking check before any GitNexus tool call.
# Designed to be called from enrichment command preambles.
#
# Usage:
#   gitnexus-check.sh [--strict] [--json] [<repo-path>]
#
# Options:
#   --strict   Use stricter staleness threshold (warn_at_commits, default 5)
#   --json     Output in JSON format
#   <repo-path> Path to check (defaults to git root of current directory)
#
# Exit codes:
#   0  Index found, not stale
#   1  Index not found (.gitnexus/meta.json missing)
#   2  Index stale (commits behind >= threshold)
#   3  Repository is a *-document repo (planning artifacts only) — skip silently

set -e

JSON_MODE=false
STRICT=false
REPO_PATH=""

for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=true ;;
        --json)   JSON_MODE=true ;;
        --help|-h)
            echo "Usage: gitnexus-check.sh [--strict] [--json] [<repo-path>]"
            exit 0
            ;;
        *)
            if [ -z "$REPO_PATH" ]; then
                REPO_PATH="$arg"
            else
                echo "ERROR: Unexpected argument '$arg'" >&2
                exit 1
            fi
            ;;
    esac
done

# Resolve repo path
if [ -z "$REPO_PATH" ]; then
    REPO_PATH=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

# Skip *-document repositories — these hold planning artifacts, not source code
REPO_NAME=$(basename "$REPO_PATH")
if [[ "$REPO_NAME" == *-document ]]; then
    if $JSON_MODE; then
        printf '{"status":"skipped","reason":"document-repo","repo":"%s","message":"*-document repositories hold planning artifacts only and are not indexed by GitNexus."}
' \
            "$(printf '%s' "$REPO_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    else
        echo "⏭️  Skipping *-document repository: $REPO_NAME (planning artifacts only)"
    fi
    exit 3
fi

# Read config thresholds
DEFAULT_THRESHOLD=10
STRICT_THRESHOLD=5
CONFIG_FILE="$REPO_PATH/.specify/extensions/gitnexus/gitnexus-config.yml"

if [ -f "$CONFIG_FILE" ]; then
    # Simple YAML parsing for threshold values
    CONFIGURED_THRESHOLD=$(grep 'threshold_commits:' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    CONFIGURED_STRICT=$(grep 'warn_at_commits:' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    [ -n "$CONFIGURED_THRESHOLD" ] && DEFAULT_THRESHOLD="$CONFIGURED_THRESHOLD"
    [ -n "$CONFIGURED_STRICT" ] && STRICT_THRESHOLD="$CONFIGURED_STRICT"
fi

if $STRICT; then
    THRESHOLD="$STRICT_THRESHOLD"
else
    THRESHOLD="$DEFAULT_THRESHOLD"
fi

# --- Check 1: Index existence ---
META_FILE="$REPO_PATH/.gitnexus/meta.json"

if [ ! -f "$META_FILE" ]; then
    if $JSON_MODE; then
        printf '{"status":"no-index","repo":"%s","message":"GitNexus index not found. Run /speckit.gitnexus.setup to index this repository."}\n' \
            "$(printf '%s' "$REPO_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    else
        echo "⚠️  GitNexus index not found at $REPO_PATH"
        echo "   Run /speckit.gitnexus.setup to index this repository."
    fi
    exit 1
fi

# --- Check 2: Staleness ---
# Extract lastCommit from meta.json (simple grep — avoids jq dependency)
LAST_COMMIT=$(grep -o '"lastCommit"[[:space:]]*:[[:space:]]*"[^"]*"' "$META_FILE" 2>/dev/null | head -1 | sed 's/.*"lastCommit"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

COMMITS_BEHIND=0
if [ -n "$LAST_COMMIT" ]; then
    # Fail-open: if git command fails, treat as not stale
    COMMITS_BEHIND=$(git -C "$REPO_PATH" rev-list --count "$LAST_COMMIT..HEAD" 2>/dev/null || echo "0")
fi

if [ "$COMMITS_BEHIND" -ge "$THRESHOLD" ] 2>/dev/null; then
    if $JSON_MODE; then
        printf '{"status":"stale","repo":"%s","commits_behind":%s,"threshold":%s,"message":"Index is %s commits behind HEAD. Run npx gitnexus analyze to update."}\n' \
            "$(printf '%s' "$REPO_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')" \
            "$COMMITS_BEHIND" "$THRESHOLD" "$COMMITS_BEHIND"
    else
        echo "⚠️  GitNexus index is $COMMITS_BEHIND commits behind HEAD (threshold: $THRESHOLD)"
        echo "   Run: npx gitnexus analyze"
    fi
    exit 2
fi

# --- All good ---
if $JSON_MODE; then
    printf '{"status":"ready","repo":"%s","commits_behind":%s,"threshold":%s}\n' \
        "$(printf '%s' "$REPO_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')" \
        "$COMMITS_BEHIND" "$THRESHOLD"
else
    echo "✅ GitNexus index is ready ($COMMITS_BEHIND commits behind HEAD)"
fi
exit 0

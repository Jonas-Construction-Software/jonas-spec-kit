#!/usr/bin/env bash
# Setup feature branches in multi-repo workspace based on tasks.md repository labels
#
# This script:
# 1. Parses tasks.md for [repo-name] labels to identify affected repositories
# 2. Creates matching feature branches in implementation repositories
# 3. Uses the same branch name as the *-document repository
#
# Usage:
#   ./setup-repo-branches.sh
#
# Environment:
#   Requires common.sh for get_feature_paths() function
#
# Exit Codes:
#   0 - Success (branches created or already exist)
#   1 - Error (missing tasks.md, git errors, etc.)

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get feature paths
eval $(get_feature_paths)

# Verify tasks.md exists
if [[ ! -f "$TASKS" ]]; then
    echo "ERROR: tasks.md not found at $TASKS" >&2
    echo "Please run /speckit.tasks first to generate the task breakdown." >&2
    exit 1
fi

# Extract unique repository names from tasks.md
# Format: - [ ] [TaskID] [P?] [Story?] [Repo] Description
# The [Repo] label is mandatory and is the last label before the description
# We filter out system labels: P, US#, T#
REPOS=$(grep -E '^\s*-\s*\[\s*\]\s*T[0-9]+' "$TASKS" 2>/dev/null | \
    grep -oP '\[([^\]]+)\]' | \
    grep -oP '(?<=\[)[^\]]+(?=\])' | \
    grep -v -E '^(P|US[0-9]+|T[0-9]+)$' | \
    sort -u || true)

# If no repository labels found, tasks.md format is incorrect
if [[ -z "$REPOS" ]]; then
    echo "ERROR: No repository labels found in tasks.md" >&2
    echo "Each task must have a [repo-name] label." >&2
    exit 1
fi

# Get the parent directory of the current repository (workspace root)
WORKSPACE_ROOT="$(cd "$REPO_ROOT/.." && pwd)"

# Get current repository name
CURRENT_REPO=$(basename "$REPO_ROOT")

# Check if all repository labels reference only the current repository
OTHER_REPOS=false
while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    if [[ "$repo" != "$CURRENT_REPO" ]]; then
        OTHER_REPOS=true
        break
    fi
done <<< "$REPOS"

if [[ "$OTHER_REPOS" == "false" ]]; then
    echo "✓ Single-repository scenario detected (all [repo-name] labels reference current repository)"
    echo "  Implementation will proceed in the current repository: $CURRENT_REPO"
    exit 0
fi

# Track if any branches were created
BRANCHES_CREATED=false
BRANCHES_EXISTED=false
REPOS_AFFECTED=()

echo "Multi-repository workspace detected"
echo "Current branch: $CURRENT_BRANCH"
echo "Repositories requiring changes:"

# For each repository, create matching branch
while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    
    REPO_PATH="$WORKSPACE_ROOT/$repo"
    
    # Check if repository exists
    if [[ ! -d "$REPO_PATH/.git" ]]; then
        echo "  ⚠  [$repo] - Repository not found at $REPO_PATH"
        continue
    fi
    
    # Skip if this is the document repository (branch already created via /speckit.specify)
    if [[ "$repo" == *-document ]]; then
        echo "  ⏭️  [$repo] - Skipping (document repository - branch already created)"
        continue
    fi
    
    # Navigate to repository
    pushd "$REPO_PATH" >/dev/null 2>&1
    
    # Check if branch exists
    if git rev-parse --verify "$CURRENT_BRANCH" >/dev/null 2>&1; then
        echo "  ✓ [$repo] - Branch '$CURRENT_BRANCH' already exists"
        BRANCHES_EXISTED=true
    else
        # Create the branch
        if git checkout -b "$CURRENT_BRANCH" >/dev/null 2>&1; then
            echo "  ✓ [$repo] - Created branch '$CURRENT_BRANCH'"
            BRANCHES_CREATED=true
        else
            echo "  ✗ [$repo] - Failed to create branch '$CURRENT_BRANCH'" >&2
            popd >/dev/null 2>&1
            continue
        fi
    fi
    
    REPOS_AFFECTED+=("$repo")
    
    # Return to original directory
    popd >/dev/null 2>&1
    
done <<< "$REPOS"

# Return to the feature repository
cd "$REPO_ROOT" 2>/dev/null || true

# Summary
echo ""
if [[ ${#REPOS_AFFECTED[@]} -eq 0 ]]; then
    echo "⚠  No repositories were affected"
    echo "   Please verify [repo-name] labels in tasks.md match actual repository names"
elif $BRANCHES_CREATED; then
    echo "✓ Multi-repository branch setup complete"
    echo "  Affected repositories: ${REPOS_AFFECTED[*]}"
    echo "  Ready to proceed with cross-repository implementation"
elif $BRANCHES_EXISTED; then
    echo "✓ All required branches already exist"
    echo "  Affected repositories: ${REPOS_AFFECTED[*]}"
fi

exit 0

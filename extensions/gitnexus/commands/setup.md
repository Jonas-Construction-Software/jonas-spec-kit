---
description: "Bootstrap GitNexus: install CLI, configure VS Code MCP server, and index workspace repositories."
---

# GitNexus Setup

This command prepares your workspace for GitNexus code intelligence. It is idempotent — safe to run multiple times.

## User Input

```text
$ARGUMENTS
```

If user input specifies particular repositories or options, incorporate them below.

---

## Step 1: Check GitNexus CLI Availability

Run the appropriate check script for the current OS:

The setup scripts live in the `*-document` repo (or the single repo) under
`.specify/extensions/gitnexus/scripts/`. In a multi-repo workspace, run them
from the document repo's root.

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-setup.sh --check
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-setup.ps1 -Check
```

If the script reports GitNexus is **not installed**:
1. Tell the user: "GitNexus CLI is not installed. Install it now with `npm install -g gitnexus@latest`?"
2. If the user agrees, run: `npm install -g gitnexus@latest`
3. Re-run the check to confirm installation succeeded

If the script reports **available-via-npx** (not globally installed, but npx can fetch it):
1. Tell the user: "GitNexus is available via npx but not installed globally. A global install is recommended for faster startup. Install globally with `npm install -g gitnexus@latest`?"
2. If the user agrees, run: `npm install -g gitnexus@latest`
3. Re-run the check to confirm it now reports **installed**

If already **installed** globally, report the version and proceed.

---

## Step 2: Configure VS Code MCP Server (User-Level)

GitNexus uses a global registry — one MCP server serves all indexed repos. Configure it at the **user level** so it works across all workspaces.

Determine the user-level `mcp.json` path based on the OS:
- **Windows**: `%APPDATA%\Code\User\mcp.json`
- **macOS**: `~/Library/Application Support/Code/User/mcp.json`
- **Linux**: `~/.config/Code/User/mcp.json`

**If the file does not exist**, create it:
```json
{
  "servers": {
    "gitnexus": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "gitnexus@latest", "mcp"]
    }
  }
}
```

**If the file exists**, read it and check whether `servers.gitnexus` is already present:
- If present: report "MCP server already configured" and skip
- If absent: add the `gitnexus` entry to the existing `servers` object, preserving all other entries

Also check if `.vscode/mcp.json` at the workspace root has an old `gitnexus` entry. If found, inform the user:
> Found a workspace-level GitNexus MCP config in `.vscode/mcp.json`. The user-level config is now the recommended location. You can remove the `gitnexus` entry from `.vscode/mcp.json` if no other workspace members depend on it.

**Important:** Tell the user:
> VS Code will show a trust dialog for the new MCP server. Click **"Allow"** when prompted to enable GitNexus tools.

---

## Step 3: Discover and Index Workspace Repositories

Scan the workspace for repositories:

1. List all top-level directories in the workspace that contain a `.git` folder
2. **Skip any repository whose name ends with `-document`** — these hold Spec Kit planning artifacts (`.specify/`) and contain no source code to index. Report them as "Skipped (planning repo)".
3. For each remaining repository, check if `.gitnexus/meta.json` exists:
   - **If exists**: Report "Already indexed" with the last-indexed date from `meta.json`
   - **If missing**: Ask the user: "Repository `<name>` is not indexed. Index it now? (Indexing may take a few minutes for large repos)"
4. For each repo the user approves, run:
   ```bash
   npx gitnexus analyze --skip-agents-md "<repo-path>"
   ```
   The `--skip-agents-md` flag prevents GitNexus from creating `AGENTS.md` and `CLAUDE.md` in each repo — Spec Kit manages AI context through its own MCP-based workflow instead.
5. **Clean up `.claude/skills/gitnexus/`** — the GitNexus CLI currently creates this folder unconditionally during analyze, even with `--skip-agents-md`. After each successful indexing, remove it:

   **macOS / Linux:**
   ```bash
   rm -rf "<repo-path>/.claude/skills/gitnexus"
   ```
   If the `.claude/skills/` or `.claude/` directory is now empty, remove it too.

   **Windows (PowerShell):**
   ```powershell
   $skillsPath = Join-Path "<repo-path>" ".claude" "skills" "gitnexus"
   if (Test-Path $skillsPath) { Remove-Item $skillsPath -Recurse -Force }
   # Clean up empty parent directories
   $parent = Join-Path "<repo-path>" ".claude" "skills"
   if ((Test-Path $parent) -and -not (Get-ChildItem $parent)) { Remove-Item $parent -Force }
   $grandparent = Join-Path "<repo-path>" ".claude"
   if ((Test-Path $grandparent) -and -not (Get-ChildItem $grandparent)) { Remove-Item $grandparent -Force }
   ```
   Tell the user: "Removed `.claude/skills/gitnexus/` — Spec Kit uses MCP tools directly and does not need per-repo skill files."
6. Wait for each indexing operation to complete and report success/failure

---

## Step 4: Verify Final State

Run the verification script:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-setup.sh --verify
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-setup.ps1 -Verify
```

> In a multi-repo workspace, ensure you run these from the `*-document` repo root
> where `.specify/` exists.

Also run `npx gitnexus list` and confirm each workspace repository appears.

---

## Step 5: Summary

Report to the user:

| Check | Status |
|-------|--------|
| GitNexus CLI | Installed (version X.Y.Z) |
| VS Code MCP | Configured (user-level mcp.json) |
| Indexed Repos | N repos indexed |

If everything passed:
> GitNexus is ready. Your AI assistant now has access to code intelligence tools (query, context, impact, detect_changes). Try `/speckit.context` to see graph-enriched context.

If any step failed, provide specific remediation instructions.

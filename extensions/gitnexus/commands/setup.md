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

If already installed, report the version and proceed.

---

## Step 2: Configure VS Code MCP Server

Check if `.vscode/mcp.json` exists at the workspace root.

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

**Important:** Tell the user:
> VS Code will show a trust dialog for the new MCP server. Click **"Allow"** when prompted to enable GitNexus tools.

---

## Step 3: Configure Other Editors (Optional)

If the user has other AI editors installed (Cursor, Claude Code, OpenCode, Codex), run the following. The command is the same on all platforms:

**macOS / Linux (bash):**
```bash
npx gitnexus setup
```

**Windows (PowerShell):**
```powershell
npx gitnexus setup
```

This configures MCP for each detected editor. Editors that are not installed are silently skipped. In a VS Code/Copilot-only environment this step produces "Skipped" for every editor and has no effect.

Report the output so the user sees what was configured vs skipped.

---

## Step 4: Discover and Index Workspace Repositories

Scan the workspace for repositories:

1. List all top-level directories in the workspace that contain a `.git` folder
2. **Skip any repository whose name ends with `-document`** — these hold Spec Kit planning artifacts (`.specify/`) and contain no source code to index. Report them as "Skipped (planning repo)".
3. For each remaining repository, check if `.gitnexus/meta.json` exists:
   - **If exists**: Report "Already indexed" with the last-indexed date from `meta.json`
   - **If missing**: Ask the user: "Repository `<name>` is not indexed. Index it now? (Indexing may take a few minutes for large repos)"
4. For each repo the user approves, run:
   ```bash
   npx gitnexus analyze "<repo-path>"
   ```
5. Wait for each indexing operation to complete and report success/failure

---

## Step 5: Verify Final State

Run the verification script:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-setup.sh --verify
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-setup.ps1 -Verify
```

Also run `npx gitnexus list` and confirm each workspace repository appears.

---

## Step 6: Summary

Report to the user:

| Check | Status |
|-------|--------|
| GitNexus CLI | ✅ Installed (version X.Y.Z) |
| VS Code MCP | ✅ Configured (.vscode/mcp.json) |
| Other Editors | ✅ Configured / ⏭️ Skipped (none detected) |
| Indexed Repos | ✅ N repos indexed |

If everything passed:
> GitNexus is ready. Your AI assistant now has access to code intelligence tools (query, context, impact, detect_changes). Try `/speckit.context` to see graph-enriched context.

If any step failed, provide specific remediation instructions.

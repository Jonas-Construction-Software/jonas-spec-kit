---
description: "Manage GitNexus indexes: view status, re-index, or clean specific repos or all repos. Supports multi-repo workspaces."
---

# GitNexus Index Maintenance

This command provides lifecycle management for existing GitNexus indexes. It assumes GitNexus is already set up — if not, direct the user to `/speckit.gitnexus.setup`.

## User Input

```text
$ARGUMENTS
```

Supported operations (inferred from user input):

| Input | Operation |
|-------|-----------|
| *(empty)* | Show status of all indexed repos, then ask what to do |
| `status` | Show status only |
| `reindex <repo-name>` | Re-index a specific repo (clean + analyze) |
| `reindex all` | Re-index all implementation repos |
| `clean <repo-name>` | Remove index for a specific repo |
| `clean all` | Remove indexes for all repos |

If the user input does not clearly match an operation, show the status table and ask which operation they'd like to perform.

---

## Guard: Check GitNexus CLI Availability

Before any operation, verify that `gitnexus` is available.

Let `$DOC_ROOT` = the root of the `*-document` repo (single-repo: the project root).

**macOS / Linux:**
```bash
bash "$DOC_ROOT/.specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh" --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$DOC_ROOT\.specify\extensions\gitnexus\scripts\powershell\gitnexus-check.ps1" -Json
```

If GitNexus CLI is not available:
> GitNexus CLI is not installed. Run `/speckit.gitnexus.setup` first.

---

## Step 1: Discover Indexed Repositories

Run `npx gitnexus list` to get all registered repositories from the global registry (`~/.gitnexus/registry.json`).

For each listed repo, also read `.gitnexus/meta.json` to gather:
- **Last indexed**: `indexedAt` timestamp
- **Symbols**: `stats.nodes` count
- **Relationships**: `stats.edges` count
- **Embeddings**: `stats.embeddings` count (0 means none)

Additionally, detect workspace repos that are **not yet indexed**:
1. List all top-level directories in the workspace that contain a `.git` folder
2. **Skip any repository whose name ends with `-document`** (planning repos have no code to index)
3. Compare against the registered list — any missing repos are "Not indexed"

Present the combined status table:

| # | Repository | Status | Last Indexed | Symbols | Relationships | Embeddings |
|---|------------|--------|--------------|---------|---------------|------------|
| 1 | my-api | ✅ Indexed | 2026-04-03 14:30 | 1,234 | 3,456 | 0 |
| 2 | my-frontend | ⚠️ Stale | 2026-03-15 09:00 | 890 | 2,100 | 512 |
| 3 | my-library | ❌ Not indexed | — | — | — | — |

**Staleness detection**: If the repo's latest git commit hash differs from `meta.json`'s `lastCommit`, mark as "⚠️ Stale".

If the user only asked for `status`, stop here. Otherwise proceed to the requested operation.

---

## Step 2: Execute the Requested Operation

### Operation: Re-index a Specific Repo

**Target selection**: If the user specified a repo name in `$ARGUMENTS`, match it against the status table. If ambiguous or not found, show the table and ask the user to pick by number or name.

**Important**: The `gitnexus clean` CLI command has a known issue on Windows where leftover database files can cause the subsequent `analyze` to fail. To avoid this, perform a **raw filesystem delete** of `.gitnexus/` instead of using `gitnexus clean`.

For the target repo (`<repo-path>`):

1. **Note whether embeddings exist** — read `<repo-path>/.gitnexus/meta.json` and check `stats.embeddings`. If greater than 0, the `--embeddings` flag will be needed to preserve them. Tell the user:
   > This repo has embeddings. Re-indexing will include `--embeddings` to regenerate them (this takes longer).

2. **Delete the existing index**:

   **macOS / Linux:**
   ```bash
   rm -rf "<repo-path>/.gitnexus"
   ```

   **Windows (PowerShell):**
   ```powershell
   Remove-Item -Recurse -Force "<repo-path>\.gitnexus"
   ```

3. **Run analyze** from inside the repo directory:

   **Without embeddings:**
   ```bash
   cd "<repo-path>" && npx gitnexus analyze --skip-agents-md
   ```

   **With embeddings** (if the repo previously had them):
   ```bash
   cd "<repo-path>" && npx gitnexus analyze --skip-agents-md --embeddings
   ```

   The `--skip-agents-md` flag prevents GitNexus from creating `AGENTS.md` and `CLAUDE.md` — Spec Kit manages AI context through its own workflow.

4. **Clean up `.claude/skills/gitnexus/`** — the GitNexus CLI creates this folder unconditionally during analyze, even with `--skip-agents-md`. After each successful indexing, remove it:

   **macOS / Linux:**
   ```bash
   rm -rf "<repo-path>/.claude/skills/gitnexus"
   ```
   If `.claude/skills/` or `.claude/` is now empty, remove it too.

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

5. **Verify**: Run `npx gitnexus list` and confirm the repo reappears with an updated timestamp.

---

### Operation: Re-index All Repos

Repeat the **Re-index a Specific Repo** steps for every implementation repo in the workspace:

1. Use the status table from Step 1
2. **Skip** repos ending with `-document` (planning repos)
3. Process repos **sequentially** (LadybugDB allows only one write transaction at a time per database, and concurrent `analyze` runs can conflict on the global registry)
4. For each repo:
   - Check for existing embeddings
   - Delete `.gitnexus/`
   - Run `npx gitnexus analyze --skip-agents-md` (add `--embeddings` if applicable)
   - Clean up `.claude/skills/gitnexus/`
5. After all repos are processed, show a summary table

---

### Operation: Clean a Specific Repo

**Target selection**: Same as re-index — match by name or ask the user to pick.

**Confirm before proceeding**:
> This will permanently delete the GitNexus index for `<repo-name>`. The repo will need to be re-indexed to use code intelligence features again. Proceed?

If the user confirms:

1. **Delete the index**:

   **macOS / Linux:**
   ```bash
   rm -rf "<repo-path>/.gitnexus"
   ```

   **Windows (PowerShell):**
   ```powershell
   Remove-Item -Recurse -Force "<repo-path>\.gitnexus"
   ```

2. **Unregister from the global registry** (so it no longer appears in `gitnexus list` and the MCP server):
   ```bash
   cd "<repo-path>" && npx gitnexus clean --force
   ```
   Note: If the `.gitnexus/` directory was already deleted, `gitnexus clean` may report "No indexed repository found" — this is fine, the registry is updated regardless.

   Alternatively, if `gitnexus clean` fails, the repo will be automatically unregistered the next time the MCP server starts and cannot find the index.

3. **Clean up `.claude/skills/gitnexus/`** if it exists (same cleanup as in the re-index operation).

---

### Operation: Clean All Repos

**Confirm before proceeding**:
> This will delete GitNexus indexes for ALL indexed repositories. You will need to re-index them to restore code intelligence. Proceed?

If the user confirms, repeat the **Clean a Specific Repo** steps for every indexed repo.

---

## Step 3: Summary

After completing the requested operation, show a results table:

| Repository | Operation | Result |
|------------|-----------|--------|
| my-api | Re-indexed | ✅ Success (1,234 symbols, 3,456 relationships) |
| my-frontend | Re-indexed | ✅ Success (890 symbols, 2,100 relationships, 512 embeddings) |
| my-library | Skipped | ℹ️ Not indexed (planning repo) |

If any operations failed, provide specific error details and remediation steps.

If the user re-indexed repos:
> Indexes are up to date. Your AI assistant's code intelligence tools (query, context, impact, detect_changes) will use the fresh data automatically.

If the user cleaned repos:
> Cleaned repos are no longer indexed. Run `/speckit.gitnexus.setup` or `/speckit.gitnexus.maintain reindex <repo>` to re-index them.

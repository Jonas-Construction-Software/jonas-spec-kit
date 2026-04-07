---
description: "Launch the GitNexus web explorer for interactive graph navigation and visualization. Supports multi-repo workspaces."
---

# GitNexus Web Explorer

## User Input

```text
$ARGUMENTS
```

---

## Guard: Check GitNexus Availability

Run the runtime guard (informational only — this command can provide setup instructions even without an index).

The guard scripts live in the `*-document` repo (or the single repo) under
`.specify/extensions/gitnexus/scripts/`. In a multi-repo workspace,
implementation repos do **not** have a `.specify/` directory, so always invoke
the script from the document repo's path and pass the target repo via the
`-RepoPath` / positional argument.

Let `$DOC_ROOT` = the root of the `*-document` repo (single-repo: the project root).

**macOS / Linux:**
```bash
bash "$DOC_ROOT/.specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh" --json "<current-repo-path>"
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$DOC_ROOT\.specify\extensions\gitnexus\scripts\powershell\gitnexus-check.ps1" -Json -RepoPath "<current-repo-path>"
```

For a **single-repo workspace** where `$DOC_ROOT` is the current repo, the
paths simplify to:

**macOS / Linux:**
```bash
bash .specify/extensions/gitnexus/scripts/bash/gitnexus-check.sh --json
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .specify/extensions/gitnexus/scripts/powershell/gitnexus-check.ps1 -Json
```

**Interpret the result:**
- `"status": "ready"` → Proceed with launch instructions
- `"status": "no-index"` → Direct the user to run `/speckit.gitnexus.setup` first
- `"status": "stale"` → Note staleness but proceed — the web UI will also show this warning
- `"status": "skipped"` (reason: `"document-repo"`) → The `*-document` repo has no code
  to visualize. Check that at least one implementation repo is indexed, then proceed.

---

## Step 1: Ensure Repos Are Indexed

**Single-repo workspace:** The current repository must have a GitNexus index.
If the guard returned `ready`, this is already satisfied.

**Multi-repo workspace:** Each implementation repository you want to explore
must be indexed individually. The `*-document` repo (planning artifacts) has no
source code to index.

If any implementation repos are not yet indexed, instruct the user:
```bash
cd <repo-name> && npx gitnexus analyze
```

Repeat for each implementation repo. All indexed repos are automatically
registered in the global registry (`~/.gitnexus/registry.json`) and will
appear in the web UI.

---

## Step 2: Start the GitNexus Backend Server

A single server instance serves **all indexed repos** — you do NOT need to
run a separate server per repository.

Instruct the user to start the server from any directory:

```bash
npx gitnexus serve
```

This starts an HTTP API on port **4747**, binding to `127.0.0.1` by default.
The server runs in the foreground — the user should run it in a separate
terminal or background it.

**Options:**
- **Alternative port:** `npx gitnexus serve --port 4748`
- **Custom host:** `npx gitnexus serve --host 0.0.0.0` (exposes to LAN — use with caution)

---

## Step 3: Open the Web UI

The GitNexus web explorer is a client-side app hosted at:

**https://gitnexus.vercel.app**

It connects to the local backend server at `http://localhost:4747`.

Tell the user:
> Open **https://gitnexus.vercel.app** in your browser. It will connect to your local GitNexus server automatically.

If the user specified a different port, they need to update the connection URL in the web UI settings.

---

## Step 4: Navigate Repos in the Explorer

**Single-repo:** The web UI loads the single indexed repo automatically.

**Multi-repo:** The web UI fetches the list of all indexed repos from the server
(`GET /api/repos`). A **repo switcher** in the UI lets the user select which
repository to visualize. Repos are viewed one at a time — switch between them
to explore different parts of the workspace.

The web UI provides:
- **Graph visualization**: Interactive force-directed graph of your codebase's call relationships
- **Cluster view**: See functional areas (communities) and how they relate
- **Process tracing**: Walk through execution flows step by step
- **Symbol search**: Find and explore any indexed symbol
- **AI chat**: Ask questions about your codebase with full graph context (requires API key)
- **Repo switcher**: Navigate between indexed repositories (multi-repo workspaces)

---

## Fallback

If GitNexus is not set up:
> The web explorer requires a GitNexus index and local server. Run `/speckit.gitnexus.setup` to get started, then use this command to launch the explorer.

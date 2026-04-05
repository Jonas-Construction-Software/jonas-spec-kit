# GitNexus Extension for Spec Kit

Integrates [GitNexus](https://gitnexus.dev) graph-based code intelligence into the Spec-Driven Development workflow.

## How It Fits the SDD Workflow

GitNexus hooks into the standard Spec Kit lifecycle at five points:

```
/speckit.context ──► before_context: enrich-context (prompted)
      │                 Adds architecture, clusters, and execution flows
      ▼                 to conversation context
/speckit.specify ──► before_specify: gap-analysis (prompted)
      │                 Story completeness + code coverage check
      ▼
/speckit.plan ─────► before_plan:  impact (prompted)
      │                 Spec-aware blast-radius analysis
      │              after_plan:   validate-plan (prompted)
      │                 Cross-checks plan against call graph
      ▼
/speckit.tasks
      │
      ▼
/speckit.implement ► before_implement: pre-flight (prompted)
      │                 Checks tasks.md symbols against call graph
      │              after_implement:  verify-changes (automatic)
      │                 Compares changes against expected task scope
      ▼
    Done

Standalone (any time):
  /speckit.gitnexus.maintain ── View status, re-index, or clean repos
  /speckit.gitnexus.explore ─── Launch the web graph explorer
```

**All hooks are optional (prompted) except `verify-changes`**, which runs automatically after implementation to catch scope creep.

## What It Does

| Command | Phase | Description |
|---------|-------|-------------|
| `speckit.gitnexus.setup` | One-time | Install CLI, configure MCP, index workspace repos |
| `speckit.gitnexus.gap-analysis` | before_specify (prompted) / Standalone | Analyse story completeness and cross-reference against existing code |
| `speckit.gitnexus.enrich-context` | before_context (prompted) | Add architecture, clusters, and execution flows to `project-context.md` |
| `speckit.gitnexus.impact` | before_plan (prompted) / Standalone | Blast-radius analysis — spec-aware auto-discovery or targeted symbol |
| `speckit.gitnexus.validate-plan` | after_plan (prompted) | Cross-check plan against call graph for unaccounted risks |
| `speckit.gitnexus.pre-flight` | before_implement (prompted) | Verify tasks.md symbols against the call graph |
| `speckit.gitnexus.verify-changes` | after_implement (automatic) | Compare staged changes against expected task scope |
| `speckit.gitnexus.explore` | Standalone | Launch the GitNexus web explorer |
| `speckit.gitnexus.maintain` | Standalone | View index status, re-index, or clean specific repos or all repos |

## Prerequisites

- **Node.js** (v18+) — for `npx` to run the GitNexus CLI
- **Git** — required for staleness checks and change detection

GitNexus itself is installed automatically during setup via `npm install -g gitnexus@latest`, or on-demand via `npx`.

## Quick Start

1. **Install the extension:**
   ```bash
   specify extension add gitnexus
   ```

2. **Run setup:**
   Use `/speckit.gitnexus.setup` in your AI assistant chat (Copilot, Claude, Cursor, etc.)

3. **Use with existing workflow:**
   - Run `/speckit.context` — the `enrich-context` hook fires automatically (opt-in prompt)
   - Run `/speckit.plan` — the `impact` hook reads your spec and shows blast radius before planning, `validate-plan` cross-checks the plan after
   - Run `/speckit.implement` — the `pre-flight` hook checks blast radius, `verify-changes` runs after

## VS Code / Copilot Setup

The `setup` command handles VS Code MCP configuration automatically:

- Creates `.vscode/mcp.json` with the correct `"servers"` schema
- VS Code will show a **trust dialog** — click **Allow** when prompted
- Adds command recommendations to `.vscode/settings.json`

## Configuration

After installation, the config file lives at `.specify/extensions/gitnexus/gitnexus-config.yml`:

```yaml
staleness:
  threshold_commits: 10   # Guard warns when index is this far behind HEAD
  warn_at_commits: 5      # Stricter threshold for pre-flight checks

analyze:
  auto_run: false          # Never auto-run analyze — always requires consent
```

## Graceful Degradation

All commands and hooks check for a valid GitNexus index before proceeding. If the index is missing or GitNexus is not installed:

- **Hooks** silently skip and let the parent Spec Kit command proceed normally
- **Standalone commands** display a message directing the user to run setup

This means installing the extension adds zero overhead to projects that haven't been indexed.

## Multi-Repo Workspaces

All commands support multi-repo workspaces out of the box:

- **Planning artifacts** (`tasks.md`, `plan.md`, `spec.md`) are read from the `*-document` repository
- **Impact analysis and change detection** run against implementation repositories using `[repo-name]` task labels
- **Guard scripts** detect `*-document` repos and skip them automatically (exit code 3)
- **Reports are per-repo**, then consolidated into a single summary

No extra configuration needed — the extension detects multi-repo workspaces automatically.

## Risk Blocking Behavior

When impact analysis discovers high-risk symbols, the extension gates the workflow:

| Risk Level | `pre-flight` Behavior | `validate-plan` Behavior |
|------------|----------------------|-------------------------|
| **CRITICAL** | **STOP** — 3-choice menu: fix first, proceed anyway, or abort | **WARN** — lists unaccounted d=1 dependents, asks to update plan |
| **HIGH** | **Pause** — requires explicit acknowledgement to continue | **WARN** — same as CRITICAL |
| **MEDIUM / LOW** | Informational — no blocking | **REVIEW** — informational only |

`verify-changes` (after implementation) uses **CLEAN / REVIEW / WARN** status to flag scope creep and phantom completions — it never blocks, but surfaces issues for user review before committing.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "GitNexus index not found" | Run `/speckit.gitnexus.setup` or `npx gitnexus analyze` in your repo |
| "Index is stale" | Run `/speckit.gitnexus.maintain reindex <repo>` or `npx gitnexus analyze` to re-index |
| VS Code MCP not working | Check `.vscode/mcp.json` exists and click "Allow" on the trust dialog |
| Multi-repo not detecting all repos | Run `npx gitnexus analyze` in each repo, then `npx gitnexus list` to verify |
| Gap analysis shows no code coverage | Expected for greenfield features — Phase 1 (requirement completeness) still runs |
| Gap analysis INSUFFICIENT but story is intentionally high-level | Choose "Proceed anyway" — the spec command will handle ambiguities |
| Re-index fails after `gitnexus clean` (Windows) | Use `/speckit.gitnexus.maintain reindex <repo>` — it performs a raw filesystem delete to avoid stale WAL files |

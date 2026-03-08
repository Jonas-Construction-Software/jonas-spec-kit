# Changelog

<!-- markdownlint-disable MD024 -->

Recent changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.20] - 2026-03-08

### Changed

- upstream merge from Spec Kit main branch (release v0.1.19) 
- fix: use GH_TOKEN for GitHub CLI in release-trigger workflow
- fix: use GITHUB_TOKEN instead of RELEASE_PAT in release-trigger workflow
- test: fix download_and_extract_template mock return values
- test: add missing show_banner mock to fix failing tests
- fix: correct step ID references in release workflow
- Add Community Walkthroughs section to README (#1766)
- feat(extensions): add Jira Integration to community catalog (#1764)
- Add Azure DevOps Integration extension to community catalog (#1734)
- Fix docs: update Antigravity link and add initialization example (#1748)
- fix: wire after_tasks and after_implement hook events into command templates (#1702)
- make c ignores consistent with c++ (#1747)
- chore: bump version to 0.1.13 (#1746)
- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)
- chore: bump version to 0.1.12 (#1737)
- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)
- fix: prepend YAML frontmatter to Cursor .mdc files (#1699)
- chore(deps): bump astral-sh/setup-uv from 6 to 7 (#1709)
- chore(deps): bump actions/setup-python from 5 to 6 (#1710)
- chore: Update outdated GitHub Actions versions (#1706)
- docs: Document dual-catalog system for extensions (#1689)
- Fix version command in documentation (#1685)


## [0.1.19] - 2024-03-02

### Changed

- **Version Sync**: Aligned version with production repository (`jonas-spec-kit`)
  - Synchronized version numbering between `jonas-spec-kit-dev` and `jonas-spec-kit` repositories
  - Both repositories now use v0.1.19 as the current version

### Changed

- feat: add kiro-cli and AGENT_CONFIG consistency coverage (#1690)
- feat: add verify extension to community catalog (#1726)
- Add Retrospective Extension to community catalog README table (#1741)
- fix(scripts): add empty description validation and branch checkout error handling (#1559)
- fix: correct Copilot extension command registration (#1724)
- fix(implement): remove Makefile from C ignore patterns (#1558)
- Add sync extension to community catalog (#1728)
- fix(checklist): clarify file handling behavior for append vs create (#1556)
- fix(clarify): correct conflicting question limit from 10 to 5 (#1557)
- chore: bump version to 0.1.12 (#1737)
- fix: use RELEASE_PAT so tag push triggers release workflow (#1736)
- fix: release-trigger uses release branch + PR instead of direct push to main (#1733)
- fix: Split release process to sync pyproject.toml version with git tags (#1732)


## [0.1.13] - 2026-03-03

### Fixed

- Version consistency between development and production repositories

## [0.1.18] - 2026-03-02

### Added

- **User Input Support in Context Command**: Enhanced `/speckit.context` workflow to accept optional user directives for guided analysis
  - Added `$ARGUMENTS` parameter support (matching `/speckit.constitution` pattern)
  - User can specify focus areas, terminology preferences, and architectural priorities
  - Remains fully optional - performs automated reverse-engineering when no input provided
  - **User Input Integration**:
    - Emphasizes user-mentioned components, patterns, or concerns throughout analysis
    - Uses domain-specific terms provided by user
    - Highlights integration points, data flows, or design decisions specified by user
    - Includes user-mentioned components prominently in generated Mermaid diagrams
    - Provides additional detail in sections relevant to user directives
  - **Benefits**:
    - Enables targeted documentation for specific architectural concerns
    - Maintains established business terminology and domain language
    - Focuses analysis on areas most relevant to current development needs
    - Improves documentation quality through human-AI collaboration

- **Intelligent Merge for Existing project-context.md Files**: Transformed context generation from "regenerate" to "update and refine"
  - **Pre-Analysis Phase (Section 2.0)**: Added preservation logic that executes before overwriting existing files
    - Reads existing `project-context.md` before creating backup
    - Extracts content for intelligent merging:
      - **Section 17 (Open Questions)**: Preserves existing questions, merges with newly discovered ones
      - **Section 18 (Guardrails & Non-Goals)**: Preserves unless contradicted by current code
      - **Section 20 (Changelog)**: Extracts all previous entries (never replaces, always appends)
      - **Terminology & Domain Language**: Notes established terms, acronyms, naming conventions
      - **Manual Clarifications**: Identifies hand-written notes, business context, editorial additions
    - Uses preserved content as analysis context to maintain consistency
    - Compares previous architectural descriptions to current source code to identify evolution
  - **Conflict Resolution Rules**:
    - **Code wins**: Fresh source code analysis overrides outdated architectural descriptions
    - **Manual wins**: Hand-written business context preserved unless directly contradicted by code
    - **Intelligent merge**: Combines lists, removes resolved questions, marks deprecated dependencies
    - **Document evolution**: Adds changelog entry noting significant changes between versions
  - **Writing Phase Updates**:
    - Phase 5 explicitly applies merge logic to sections 17, 18, and 20
    - Changelog template updated to note preservation requirement with example
    - Pre-write phase references completed pre-analysis
  - **Benefits**:
    - Preserves institutional knowledge and manual refinements across regenerations
    - Maintains business context that cannot be inferred from code alone
    - Documents architectural evolution over time in changelog
    - Prevents loss of carefully crafted guardrails and open questions
    - Makes documentation a living artifact that improves with each update

## [0.1.17] - 2026-03-02

### Added

- **Multi-Repository Workspace Auto-Switching for Planning Commands**: Standardized repository location validation across all planning commands
  - **All Planning Commands** (`constitution.md`, `specify.md`, `clarify.md`, `plan.md`, `tasks.md`, `analyze.md`):
    - Added "Step 0: Repository Location Validation (Multi-Repo Workspaces)" section
    - Commands now automatically detect multi-repo vs single-repo workspaces
    - **Automatic switching**: When run from an implementation repository, commands automatically switch to the `*-document` repository before execution
    - Reports switching action: `📂 Switched to planning repository: <repo-name>-document`
    - Provides clear error if `*-document` repository not found in multi-repo workspace
    - Single-repo workspaces skip validation entirely (no performance impact)
  - **Benefits**:
    - Users can run planning commands from any repository in the workspace
    - Ensures planning artifacts are always created in the correct location
    - Fail-fast behavior with clear error messages
    - Transparent and automatic - no manual navigation required
  - **Exception**: `/speckit.context` intentionally runs from implementation repos and skips `*-document` repositories

### Changed

- **README.md Workflow Reordering**: Updated "Get Started" section to reflect recommended workflow sequence
  - **Step 2**: Gather implementation context (`/speckit.context`) - moved from step 3
  - **Step 3**: Establish project principles (`/speckit.constitution`) - moved from step 2
  - Rationale: Context gathering should occur before establishing principles to inform principle creation
  - Updated "Detailed Process" section to match the new ordering

## [0.1.16] - 2026-03-01

### Fixed

- **PowerShell Parameter Binding Issue in Feature Creation Script**: Resolved PowerShell parameter binding error when using `-Json` switch with positional arguments
  - **Issue**: Command `create-new-feature.ps1 -Json -CustomPrefix "OCR-338" -ShortName "analysis-stuck-actions" "Improve UX for stuck analysis"` failed with error: `Cannot convert value "Improve UX for stuck analysis" to type "System.Boolean"`
  - **Root Cause**: PowerShell's parameter binding algorithm incorrectly attempted to bind the positional feature description string to the `-Json` switch parameter
  - **PowerShell Script (`create-new-feature.ps1`)**:
    - Added explicit `-Description` parameter as the first parameter to prevent binding confusion
    - Maintained backward compatibility with `ValueFromRemainingArguments` for positional usage
    - Combines both parameter values if somehow both are provided
    - Updated help documentation with recommended and legacy usage patterns
  - **Bash Script (`create-new-feature.sh`)**:
    - Added matching `--description` parameter for consistency with PowerShell version
    - Ensures identical interface across both platforms
    - Maintains backward compatibility with positional arguments
    - Updated help documentation to match PowerShell examples
  - **Specify Workflow (`specify.md`)**:
    - Updated script invocations to use explicit description parameter: `-Description "{ARGS}"` (PowerShell) and `--description "{ARGS}"` (Bash)
    - Updated all example commands throughout the document to use recommended explicit parameter syntax
  - **Benefits**:
    - Prevents parameter binding confusion when using switches with positional arguments
    - Provides consistent, self-documenting interface across both scripts
    - Maintains full backward compatibility with existing usage patterns
    - Improves robustness and clarity of script invocations

## [0.1.15] - 2026-03-01

### Enhanced

- **Jira Development Task Discovery Enhancement**: Expanded development task retrieval to check both subtasks and linked issues when importing from Jira user stories
  - **Specify Workflow (`specify.md`)**:
    - Now retrieves development tasks from both `subtasks` and `issuelinks` fields when fetching Jira user stories
    - Added processing for linked issues with relevant link types: "implements", "is implemented by", "relates to", "depends on", "rolls up into", "breaks down into"
    - Filters linked issues by issue type (Development Task, Dev Task, Task, Technical Task) and keywords
    - Excludes non-development link types (duplicates, blocks) unless they are development tasks
    - Combines and deduplicates subtasks and linked issues into unified development task list
    - Updated presentation table to include "Source" column indicating whether task is a subtask or linked issue
    - Stores both `JIRA_SUBTASKS` and `JIRA_LINKED_ISSUES` variables for branch naming workflow
  - **Benefits**:
    - Provides more comprehensive view of development tasks associated with user stories
    - Supports different Jira workflows where development tasks may be represented as linked issues instead of subtasks
    - Improves flexibility for teams using various Jira issue linking strategies
    - Maintains backward compatibility with existing subtask-only workflows

- **Context Command Backup Deletion Optimization**: Improved clarity and reliability of backup file cleanup in reverse-engineering workflow
  - **Context Workflow (`context.md`)**:
    - Made Post-Write Phase backup deletion instructions more explicit and actionable
    - Bolded deletion command to emphasize required action
    - Added explicit file pattern reference (`project-context.md.backup.YYYYMMDD_HHMMSS`)
    - Added directive "(use file deletion operation)" to signal concrete action required
    - Added confirmation step to verify deletion succeeded
    - Made restoration steps more explicit with detailed copy operation instructions
  - **Benefits**:
    - Prevents agents from skipping or misinterpreting backup cleanup step
    - Reduces user intervention required during project-context.md generation
    - Improves workflow reliability and user experience
    - Ensures cleanup happens automatically after successful verification

## [0.1.14] - 2026-02-28

### Added

- **Jira Development Task Auto-Discovery in Specify Workflow**: Enhanced feature branch creation with automatic retrieval of development tasks from imported user stories
  - **Specify Workflow (`specify.md`)**:
    - Added automatic retrieval of subtasks from imported Jira user stories
    - Filters subtasks to identify development tasks by type and keywords
    - Presents available development tasks in formatted table with options to:
      - Select an existing development task (1, 2, 3, etc.)
      - Enter a different task manually (M)
      - Skip and use auto-numbering (N)
    - Auto-discovery only executes when user imports from Jira in Step 0
    - Falls back to manual input if no development tasks found or MCP server fails
    - Stores Jira context variables (`JIRA_STORY_IMPORTED`, `JIRA_STORY_KEY`, `JIRA_CLOUD_ID`, `JIRA_SUBTASKS`) for later use
  - **Benefits**:
    - Eliminates manual task key entry when development tasks already exist in Jira
    - Provides better visibility into available development tasks associated with user story
    - Streamlines workflow for teams using Jira for task management
    - Maintains flexibility with manual entry and auto-numbering fallback options

### Changed

- **Customized for Jonas Construction Software**: Rebranded and customized jonas-spec-kit fork
  - Updated all repository URLs from `github/spec-kit` to `Jonas-Construction-Software/jonas-spec-kit`
  - Updated README description to reflect customization for Jonas Construction Software's workflow
  - Updated installation and upgrade commands with new repository location
  - Reordered core commands table to prioritize `/speckit.context` as first command
  - Enhanced acknowledgements section to credit original GitHub Spec Kit project
  - Updated GitHub Pages documentation URL
  - Updated support and issue tracking URL

## [0.1.13] - 2026-02-27

### Fixed

- **Implement Command Template**: Replaced placeholder with explicit script paths
  - Replaced `{BRANCH_SETUP_SCRIPT}` placeholder with explicit Bash and PowerShell script paths
  - Added separate code blocks for `scripts/bash/setup-repo-branches.sh` and `scripts/powershell/setup-repo-branches.ps1`
  - Ensures AI agents can correctly execute multi-repository branch setup regardless of platform
  - Follows established pattern used in other command templates for cross-platform compatibility

## [0.1.12] - 2026-02-27

### Added

- **Repository Branch Setup Scripts**: Added automated scripts for creating feature branches across multi-repository workspaces
  - `scripts/bash/setup-repo-branches.sh`: Bash implementation for Unix-like systems
  - `scripts/powershell/setup-repo-branches.ps1`: PowerShell implementation for Windows
  - Automatically detects multi-repo workspaces and creates matching feature branches
  - Parses `tasks.md` for `[repo-name]` labels to identify affected repositories
  - Handles both single-repo and multi-repo scenarios seamlessly

### Changed

- **Analyze Command Template**: Enhanced multi-repository awareness
  - Added comprehensive handoff templates for post-analysis workflow transitions
  - Improved documentation of handoff patterns and checklist generation
  - Enhanced cross-repository constraint validation

- **Implement Command Template**: Added explicit no-commit policy
  - Added **DO NOT commit changes** instruction in completion validation (step 9)
  - Added **DO NOT commit changes in any repository** for multi-repo scenarios (step 10)
  - Added prominent final reminder that all changes must remain uncommitted for user review
  - Prevents automatic commits after implementation, requiring explicit user approval

- **Tasks Command Template**: Improved task format validation
  - Enhanced `[Repo]` label requirement documentation
  - Clarified checklist format with better examples
  - Added explicit repository label examples for single-repo and multi-repo scenarios

- **Tasks Template**: Updated task structure documentation
  - Refined phase organization and task ordering guidelines
  - Enhanced parallel task execution rules
  - Improved repository label format documentation

## [0.1.10] - 2026-02-27

### Added

- **Multi-Repository Workspace Support in Plan and Tasks Workflows**: Extended multi-repo capabilities from clarify workflow to plan and tasks workflows
  - **Plan Workflow (`plan.md`)**:
    - Added multi-repository detection to identify workspace structure and active repository location
    - Loads `project-context.md` files from multiple repositories to understand system-wide architecture
    - Pre-populates technical context with known constraints from architectural documentation
    - Validates plan against cross-repository architectural constraints
    - Generates cross-repository impact summary listing affected repositories and integration points
    - Documents shared contracts, data models, and service boundaries that span repositories
    - Includes research tasks for cross-repository integration patterns
    - Ensures contracts align with existing repository contracts when cross-repo dependencies exist
  - **Tasks Workflow (`tasks.md`)**:
    - Detects multi-repository workspaces and identifies active repository from `FEATURE_DIR` path
    - Loads architectural context from `project-context.md` files in relevant repositories
    - Maps cross-repository dependencies from plan to task organization
    - Validates contract changes don't break existing integrations in other repositories
    - Adds `[Repo]` label to task format for multi-repo tasks (e.g., `- [ ] [TaskID] [P1] [S1] [repo-name] Description`)
    - Includes cross-repository dependencies in task dependency graph
    - Generates contract validation and compatibility check tasks for shared APIs
    - Documents cross-repository task summary with coordination requirements
  - Maintains full backward compatibility with single-repository projects

- **Jira Development Task Integration in Specify Workflow**: Enhanced feature branch creation with optional Jira task number support
  - **Specify Workflow (`specify.md`)**:
    - Added upfront prompt for Jira development task number before branch creation (e.g., FT-53, DEV-142, PROJ-789)
    - Validates Jira key format using pattern `[A-Z]+-\d+`
    - Supports two branch naming modes:
      1. **Jira mode**: Uses dev task key as prefix (e.g., `FT-53-user-auth`)
      2. **Auto-numbering mode**: Uses sequential numbers (e.g., `001-user-auth`)
    - Ensures consistent branch and directory naming based on selected mode
    - Moved Jira prompt to beginning of workflow for better UX (before any resource creation)
  - **Feature Creation Scripts**:
    - Added `--custom-prefix` option to `create-new-feature.sh` (Bash)
    - Added `-CustomPrefix` parameter to `create-new-feature.ps1` (PowerShell)
    - Validates custom prefix format and provides clear error messages
    - Updated help documentation and usage examples for both scripts
  - **Benefits**:
    - Provides clear feature branch traceability back to Jira development tasks
    - Enables teams to quickly identify which Jira task a feature branch implements
    - Supports existing auto-numbering workflow for teams not using Jira
    - Improves project management integration and developer workflow

### Changed

- **Improved Specify Workflow Branch Naming Strategy**: Restructured branch creation logic for better clarity and maintainability
  - Separated branch naming strategy determination into explicit first step
  - Made Jira integration opt-in with clear Yes/No prompt at beginning
  - Consolidated branch numbering logic to avoid duplication
  - Enhanced documentation of branch creation process with clearer examples

## [0.1.8] - 2026-02-26

### Enhanced

- **Multi-Repository Workspace Support in Clarification Workflow**: Enhanced `clarify.md` template to intelligently handle multi-repository workspaces
  - Added multi-repository detection in setup phase to identify workspace structure and locate active repository
  - Loads `project-context.md` files from repositories to understand architectural constraints
  - Added new "Multi-Repository Context" taxonomy category for coverage scanning (cross-repo dependencies, shared contracts, service boundaries)
  - Prioritizes clarification questions about cross-repository integration points and architectural alignment
  - Validates clarifications against `project-context.md` constraints during integration
  - Reports architectural alignment and cross-repository dependencies in completion summary
  - Maintains backward compatibility with single-repository projects

## [0.1.6] - 2026-02-23

### Fixed

- **Parameter Ordering Issues (#1641)**: Fixed CLI parameter parsing issue where option flags were incorrectly consumed as values for preceding options
  - Added validation to detect when `--ai` or `--ai-commands-dir` incorrectly consume following flags like `--here` or `--ai-skills`
  - Now provides clear error messages: "Invalid value for --ai: '--here'"
  - Includes helpful hints suggesting proper usage and listing available agents
  - Commands like `specify init --ai-skills --ai --here` now fail with actionable feedback instead of confusing "Must specify project name" errors
  - Added comprehensive test suite (5 new tests) to prevent regressions

## [0.1.5] - 2026-02-21

### Fixed

- **AI Skills Installation Bug (#1658)**: Fixed `--ai-skills` flag not generating skill files for GitHub Copilot and other agents with non-standard command directory structures
  - Added `commands_subdir` field to `AGENT_CONFIG` to explicitly specify the subdirectory name for each agent
  - Affected agents now work correctly: copilot (`.github/agents/`), opencode (`.opencode/command/`), windsurf (`.windsurf/workflows/`), codex (`.codex/prompts/`), kilocode (`.kilocode/workflows/`), q (`.amazonq/prompts/`), and agy (`.agent/workflows/`)
  - The `install_ai_skills()` function now uses the correct path for all agents instead of assuming `commands/` for everyone

## [0.1.4] - 2026-02-20

### Fixed

- **Qoder CLI detection**: Renamed `AGENT_CONFIG` key from `"qoder"` to `"qodercli"` to match the actual executable name, fixing `specify check` and `specify init --ai` detection failures

## [0.1.3] - 2026-02-20

### Added

- **Generic Agent Support**: Added `--ai generic` option for unsupported AI agents ("bring your own agent")
  - Requires `--ai-commands-dir <path>` to specify where the agent reads commands from
  - Generates Markdown commands with `$ARGUMENTS` format (compatible with most agents)
  - Example: `specify init my-project --ai generic --ai-commands-dir .myagent/commands/`
  - Enables users to start with Spec Kit immediately while their agent awaits formal support

## [0.0.102] - 2026-02-20

- fix: include 'src/**' path in release workflow triggers (#1646)

## [0.0.101] - 2026-02-19

- chore(deps): bump github/codeql-action from 3 to 4 (#1635)

## [0.0.100] - 2026-02-19

- Add pytest and Python linting (ruff) to CI (#1637)
- feat: add pull request template for better contribution guidelines (#1634)

## [0.0.99] - 2026-02-19

- Feat/ai skills (#1632)

## [0.0.98] - 2026-02-19

- chore(deps): bump actions/stale from 9 to 10 (#1623)
- feat: add dependabot configuration for pip and GitHub Actions updates (#1622)

## [0.0.97] - 2026-02-18

- Remove Maintainers section from README.md (#1618)

## [0.0.96] - 2026-02-17

- fix: typo in plan-template.md (#1446)

## [0.0.95] - 2026-02-12

- Feat: add a new agent: Google Anti Gravity (#1220)

## [0.0.94] - 2026-02-11

- Add stale workflow for 180-day inactive issues and PRs (#1594)

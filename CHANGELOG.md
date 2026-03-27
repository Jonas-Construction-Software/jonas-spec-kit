# Changelog

<!-- insert new changelog below this comment -->

## [0.1.21] - 2026-03-27

### Changed

- chore: sync from dev repo - bump to v0.1.21 (#7)

## [0.1.21] - 2026-03-27

### Changed

- fix version detection with release trigger
- Feature/upstream sync main 2026 03 25 (#10)
- Update CHANGELOG.md
- chore: bump version to 0.1.20
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

## [0.1.21] - 2026-03-26

### Changed

- upstream merge from Spec Kit main branch (release v0.4.2)

## 0.4.2 (upstream) - 2026-03-25

### Changed

- feat: Auto-register ai-skills for extensions whenever applicable (#1840)
- docs: add manual testing guide for slash command validation (#1955)
- Add AIDE, Extensify, and Presetify to community extensions (#1961)
- docs: add community presets section to main README (#1960)
- docs: move community extensions table to main README for discoverability (#1959)
- docs(readme): consolidate Community Friends sections and fix ToC anchors (#1958)
- fix(commands): rename NFR references to success criteria in analyze and clarify (#1935)
- Add Community Friends section to README (#1956)
- docs: add Community Friends section with Spec Kit Assistant VS Code extension (#1944)

## 0.4.1 (upstream) - 2026-03-24

### Changed

- Add checkpoint extension (#1947)
- fix(scripts): prioritize .specify over git for repo root detection (#1933)
- docs: add AIDE extension demo to community projects (#1943)
- fix(templates): add missing Assumptions section to spec template (#1939)

## 0.4.0 (upstream) - 2026-03-23

### Changed

- fix(cli): add allow_unicode=True and encoding="utf-8" to YAML I/O (#1936)
- fix(codex): native skills fallback refresh + legacy prompt suppression (#1930)
- feat(cli): embed core pack in wheel for offline/air-gapped deployment (#1803)
- ci: increase stale workflow operations-per-run to 250 (#1922)
- docs: update publishing guide with Category and Effect columns (#1913)
- fix: Align native skills frontmatter with install_ai_skills (#1920)
- feat: add timestamp-based branch naming option for `specify init` (#1911)
- docs: add Extension Comparison Guide for community extensions (#1897)
- docs: update SUPPORT.md, fix issue templates, add preset submission template (#1910)
- Add support for Junie (#1831)
- feat: migrate Codex/agy init to native skills workflow (#1906)

## 0.3.2 (upstream) - 2026-03-19

### Changed

- Add conduct extension to community catalog (#1908)
- feat(extensions): add verify-tasks extension to community catalog (#1871)
- feat(presets): add enable/disable toggle and update semantics (#1891)
- feat: add iFlow CLI support (#1875)
- feat(commands): wire before/after hook events into specify and plan templates (#1886)
- docs(catalog): add speckit-utils to community catalog (#1896)
- docs: Add Extensions & Presets section to README (#1898)
- chore: update DocGuard extension to v0.9.11 (#1899)
- Update cognitive-squad catalog entry — Triadic Model, full lifecycle (#1884)
- feat: register spec-kit-iterate extension (#1887)
- fix(scripts): add explicit positional binding to PowerShell create-new-feature params (#1885)
- fix(scripts): encode residual JSON control chars as \uXXXX instead of stripping (#1872)
- chore: update DocGuard extension to v0.9.10 (#1890)
- Feature/spec kit add pi coding agent pullrequest (#1853)
- feat: register spec-kit-learn extension (#1883)

## 0.3.1 (upstream) - 2026-03-17

### Changed

- docs: add greenfield Spring Boot pirate-speak preset demo to README (#1878)
- fix(ai-skills): exclude non-speckit copilot agent markdown from skills (#1867)
- feat: add Trae IDE support as a new agent (#1817)
- feat(cli): polite deep merge for settings.json and support JSONC (#1874)
- feat(extensions,presets): add priority-based resolution ordering (#1855)
- fix(scripts): suppress stdout from git fetch in create-new-feature.sh (#1876)
- fix(scripts): harden bash scripts — escape, compat, and error handling (#1869)
- Add cognitive-squad to community extension catalog (#1870)
- docs: add Go / React brownfield walkthrough to community walkthroughs (#1868)
- chore: update DocGuard extension to v0.9.8 (#1859)
- Feature: add specify status command (#1837)
- fix(extensions): show extension ID in list output (#1843)
- feat(extensions): add Archive and Reconcile extensions to community catalog (#1844)
- feat: Add DocGuard CDD enforcement extension to community catalog (#1838)

## 0.3.0 (upstream) - 2026-03-13

### Changed

- feat(presets): Pluggable preset system with catalog, resolver, and skills propagation (#1787)
- fix: match 'Last updated' timestamp with or without bold markers (#1836)
- Add specify doctor command for project health diagnostics (#1828)
- fix: harden bash scripts against shell injection and improve robustness (#1809)
- fix: clean up command templates (specify, analyze) (#1810)
- fix: migrate Qwen Code CLI from TOML to Markdown format (#1589) (#1730)
- fix(cli): deprecate explicit command support for agy (#1798) (#1808)
- Add /selftest.extension core extension to test other extensions (#1758)
- feat(extensions): Quality of life improvements for RFC-aligned catalog integration (#1776)
- Add Java brownfield walkthrough to community walkthroughs (#1820)

## 0.2.1 (upstream) - 2026-03-11

### Changed

- Added February 2026 newsletter (#1812)
- feat: add Kimi Code CLI agent support (#1790)
- docs: fix broken links in quickstart guide (#1759) (#1797)
- docs: add catalog cli help documentation (#1793) (#1794)
- fix: use quiet checkout to avoid exception on git checkout (#1792)
- feat(extensions): support .extensionignore to exclude files during install (#1781)
- feat: add Codex support for extension command registration (#1767)

## 0.2.0 (upstream) - 2026-03-09

### Changed

- fix: sync agent list comments with actual supported agents (#1785)
- feat(extensions): support multiple active catalogs simultaneously (#1720)
- Pavel/add tabnine cli support (#1503)
- Add Understanding extension to community catalog (#1778)
- Add ralph extension to community catalog (#1780)
- Update README with project initialization instructions (#1772)
- feat: add review extension to community catalog (#1775)
- Add fleet extension to community catalog (#1771)
- Integration of Mistral vibe support into speckit (#1725)
- fix: Remove duplicate options in specify.md (#1765)
- fix: use global branch numbering instead of per-short-name detection (#1757)
- Add Community Walkthroughs section to README (#1766)
- feat(extensions): add Jira Integration to community catalog (#1764)
- Add Azure DevOps Integration extension to community catalog (#1734)
- Fix docs: update Antigravity link and add initialization example (#1748)
- fix: wire after_tasks and after_implement hook events into command templates (#1702)
- make c ignores consistent with c++ (#1747)

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

### Changed

- Add Cleanup Extension to catalog (#1617)
- Fix parameter ordering issues in CLI (#1669)
- Update V-Model Extension Pack to v0.4.0 (#1665)
- docs: Fix doc missing step (#1496)
- Update V-Model Extension Pack to v0.3.0 (#1661)

## [0.1.5] - 2026-02-21

### Changed

- Fix #1658: Add commands_subdir field to support non-standard agent directory structures (#1660)
- feat: add GitHub issue templates (#1655)
- Update V-Model Extension Pack to v0.2.0 in community catalog (#1656)
- Add V-Model Extension Pack to catalog (#1640)
- refactor: remove OpenAPI/GraphQL bias from templates (#1652)

## [0.1.4] - 2026-02-20

### Changed

- fix: rename Qoder AGENT_CONFIG key from 'qoder' to 'qodercli' to match actual CLI executable (#1651)

## [0.1.3] - 2026-02-20

### Changed

- Add generic agent support with customizable command directories (#1639)

## [0.1.2] - 2026-02-20

### Changed

- fix: pin click>=8.1 to prevent Python 3.14/Homebrew env isolation crash (#1648)

## [0.0.102] - 2026-02-20

### Changed

- fix: include 'src/**' path in release workflow triggers (#1646)

## [0.0.101] - 2026-02-19

### Changed

- chore(deps): bump github/codeql-action from 3 to 4 (#1635)

## [0.0.100] - 2026-02-19

### Changed

- Add pytest and Python linting (ruff) to CI (#1637)
- feat: add pull request template for better contribution guidelines (#1634)

## [0.0.99] - 2026-02-19

### Changed

- Feat/ai skills (#1632)

## [0.0.98] - 2026-02-19

### Changed

- chore(deps): bump actions/stale from 9 to 10 (#1623)
- feat: add dependabot configuration for pip and GitHub Actions updates (#1622)

## [0.0.97] - 2026-02-18

### Changed

- Remove Maintainers section from README.md (#1618)

## [0.0.96] - 2026-02-17

### Changed

- fix: typo in plan-template.md (#1446)

## [0.0.95] - 2026-02-12

### Changed

- Feat: add a new agent: Google Anti Gravity (#1220)

## [0.0.94] - 2026-02-11

### Changed

- Add stale workflow for 180-day inactive issues and PRs (#1594)

## [0.0.93] - 2026-02-10

### Changed

- Add modular extension system (#1551)

## [0.0.92] - 2026-02-10

### Changed

- Fixes #1586 - .specify.specify path error (#1588)

## [0.0.91] - 2026-02-09

### Changed

- fix: preserve constitution.md during reinitialization (#1541) (#1553)
- fix: resolve markdownlint errors across documentation (#1571)

## [0.0.90] - 2025-12-04

### Changed

- Update Markdown formatting
- Update Markdown formatting
- docs: Add existing project initialization to getting started

## [0.0.89] - 2025-12-02

### Changed

- Update scripts/bash/create-new-feature.sh
- fix(scripts): prevent octal interpretation in feature number parsing
- fix: remove unused short_name parameter from branch numbering functions
- Update scripts/powershell/create-new-feature.ps1
- Update scripts/bash/create-new-feature.sh
- fix: use global maximum for branch numbering to prevent collisions

## [0.0.88] - 2025-12-01

### Changed

- fix the incorrect task-template file path

## [0.0.87] - 2025-12-01

### Changed

- Limit width and height to 200px to match the small logo
- docs: Switch readme logo to logo_large.webp
- fix:merge
- fix
- fix
- feat:qoder agent
- docs: Enhance quickstart guide with admonitions and examples
- docs: add constitution step to quickstart guide (fixes #906)
- Update supported AI agents in README.md
- cancel:test
- test
- fix:literal bug
- fix:test
- test
- fix:qoder url
- fix:download owner
- test
- feat:support Qoder CLI

## [0.0.86] - 2025-11-26

### Changed

- feat: add bob to new update-agent-context.ps1 + consistency in comments
- feat: add support for IBM Bob IDE

## [0.0.85] - 2025-11-14

### Changed

- Unset CDPATH while getting SCRIPT_DIR

## [0.0.84] - 2025-11-14

### Changed

- docs: fix broken link and improve agent reference
- docs: reorganize upgrade documentation structure
- docs: remove related documentation section from upgrading guide
- fix: remove broken link to existing project guide
- docs: Add comprehensive upgrading guide for Spec Kit
- Refactor ESLint configuration checks in implement.md to address deprecation

## [0.0.83] - 2025-11-14

### Changed

- feat: Add OVHcloud SHAI AI Agent

## [0.0.82] - 2025-11-14

### Changed

- fix: incorrect logic to create release packages with subset AGENTS or SCRIPTS

## [0.0.81] - 2025-11-14

### Changed

- Fix tasktoissues.md to use the 'github/github-mcp-server/issue_write' tool

## [0.0.80] - 2025-11-14

### Changed

- Refactor feature script logic and update agent context scripts
- Update templates/commands/taskstoissues.md
- Update CHANGELOG.md
- Update agent configuration
- Update scripts/powershell/create-new-feature.ps1
- Update src/specify_cli/__init__.py
- Create create-release-packages.ps1
- Script changes
- Update taskstoissues.md
- Create taskstoissues.md
- Update src/specify_cli/__init__.py
- Update CONTRIBUTING.md
- Potential fix for code scanning alert no. 3: Workflow does not contain permissions
- Update src/specify_cli/__init__.py
- Update CHANGELOG.md
- Fixes #970
- Fixes #975
- Support for version command
- Exclude generated releases
- Lint fixes
- Prompt updates
- Hand offs with prompts
- Chatmodes are back in vogue
- Let's switch to proper prompts
- Update prompts
- Update with prompt
- Testing hand-offs
- Use VS Code handoffs

## [0.0.79] - 2025-10-23

### Changed

- docs: restore important note about JSON output in specify command
- fix: improve branch number detection to check all sources
- feat: check remote branches to prevent duplicate branch numbers

## [0.0.78] - 2025-10-21

### Changed

- Update CONTRIBUTING.md
- docs: add steps for testing template and command changes locally
- update specify to make "short-name" argu for create-new-feature.sh in the right position

## [0.0.77] - 2025-10-21

### Changed

- fix: include the latest changelog in the `GitHub Release`'s  body

## [0.0.76] - 2025-10-21

### Changed

- Fix update-agent-context.sh to handle files without Active Technologies/Recent Changes sections

## [0.0.75] - 2025-10-21

### Changed

- Fixed indentation.
- Added correct `install_url` for Amp agent CLI script.
- Added support for Amp code agent.

## [0.0.74] - 2025-10-21

### Changed

- feat(ci): add markdownlint-cli2 for consistent markdown formatting

## [0.0.73] - 2025-10-21

### Changed

- revert vscode auto remove extra space
- fix: correct command references in implement.md
- fix regarding copilot suggestion
- fix: correct command references in speckit.analyze.md
- Support more lang/Devops of Common Patterns by Technology
- chore: replace `bun` by `node/npm` in the `devcontainer` (as many CLI-based agents actually require a `node` runtime)
- chore: add Claude Code extension to devcontainer configuration
- chore: add installation of `codebuddy` CLI in the `devcontainer`
- chore: fix path to powershell script in vscode settings
- fix: correct `run_command` exit behavior and improve installation instructions (for `Amazon Q`) in `post-create.sh` + fix typos in `CONTRIBUTING.md`
- chore: add `specify`'s github copilot chat settings to `devcontainer`
- chore: add `devcontainer` support  to ease developer workstation setup

## [0.0.72] - 2025-10-18

### Changed

- fix: correct argument parsing in create-new-feature.sh script

## [0.0.71] - 2025-10-18

### Changed

- fix: Skip CLI checks for IDE-based agents in check command
- Change loop condition to include last argument

## [0.0.70] - 2025-10-18

### Changed

- fix: broken media files
- Update README.md
- The function parameters lack type hints. Consider adding type annotations for better code clarity and IDE support.
- - **Smart JSON Merging for VS Code Settings**: `.vscode/settings.json` is now intelligently merged instead of being overwritten during `specify init --here` or `specify init .`   - Existing settings are preserved   - New Spec Kit settings are added   - Nested objects are merged recursively   - Prevents accidental loss of custom VS Code workspace configurations
- Fix: incorrect command formatting in agent context file, refix #895

## [0.0.69] - 2025-10-15

### Changed

- Update scripts/bash/create-new-feature.sh
- Update create-new-feature.sh
- Update files
- Update files
- Create .gitattributes
- Update wording
- Update logic for arguments
- Update script logic

## [0.0.68] - 2025-10-15

### Changed

- format content as copilot suggest
- Ruby, PHP, Rust, Kotlin, C, C++

## [0.0.67] - 2025-10-15

### Changed

- Use the number prefix to find the right spec

## [0.0.66] - 2025-10-15

### Changed

- Update CodeBuddy agent name to 'CodeBuddy CLI'
- Rename CodeBuddy to CodeBuddy CLI in update script
- Update AI coding agent references in installation guide
- Rename CodeBuddy to CodeBuddy CLI in AGENTS.md
- Update README.md
- Update CodeBuddy link in README.md
- update codebuddyCli

## [0.0.65] - 2025-10-15

### Changed

- Fix: Fix incorrect command formatting in agent context file
- docs: fix heading capitalization for consistency
- Update README.md

## [0.0.64] - 2025-10-14

### Changed

- Update tasks.md
- Update README.md

## [0.0.63] - 2025-10-14

### Changed

- fix: update CODEBUDDY file path in agent context scripts
- docs(readme): add /speckit.tasks step and renumber walkthrough

## [0.0.62] - 2025-10-11

### Changed

- A few more places to update from code review
- fix: align Cursor agent naming to use 'cursor-agent' consistently

## [0.0.61] - 2025-10-10

### Changed

- Update clarify.md
- add how to upgrade specify installation

## [0.0.60] - 2025-10-10

### Changed

- Update vscode-settings.json
- Update instructions and bug fix

## [0.0.59] - 2025-10-10

### Changed

- Update __init__.py
- Consolidate Cursor naming
- Update CHANGELOG.md
- Git errors are now highlighted.
- Update __init__.py
- Refactor agent configuration
- Update src/specify_cli/__init__.py
- Update scripts/powershell/update-agent-context.ps1
- Update AGENTS.md
- Update templates/commands/implement.md
- Update templates/commands/implement.md
- Update CHANGELOG.md
- Update changelog
- Update plan.md
- Add ignore file verification step to /speckit.implement command
- Escape backslashes in TOML outputs
- update CodeBuddy to international site
- feat: support codebuddy ai
- feat: support codebuddy ai

## [0.0.58] - 2025-10-08

### Changed

- Add escaping guidelines to command templates
- Update README.md
- Update README.md

## [0.0.57] - 2025-10-06

### Changed

- Update CHANGELOG.md
- Update command reference
- Package up VS Code settings for Copilot
- Update tasks-template.md
- Update templates/tasks-template.md
- Cleanup
- Update CLI changes
- Update template and docs
- Update checklist.md
- Update templates
- Cleanup redundancies
- Update checklist.md
- Codex CLI is now fully supported
- Update specify.md
- Prompt updates
- Update prompt prefix
- Update .github/workflows/scripts/create-release-packages.sh
- Consistency updates to commands
- Update commands.
- Update logs
- Template cleanup and reorganization
- Remove Codex named args limitation warning
- Remove Codex named args limitation from README.md

## [0.0.56] - 2025-10-02

### Changed

- docs(readme): link Amazon Q slash command limitation issue
- docs: clarify Amazon Q limitation and update init docstring
- feat(agent): Added Amazon Q Developer CLI Integration

## [0.0.55] - 2025-09-30

### Changed

- Update URLs to Contributing and Support Guides in Docs
- fix: add UTF-8 encoding to file read/write operations in update-agent-context.ps1
- Update __init__.py
- Update src/specify_cli/__init__.py
- docs: fix the paths of generated files (moved under a `.specify/` folder)
- Update src/specify_cli/__init__.py
- feat: support 'specify init .' for current directory initialization
- feat: Add emacs-style up/down keys

## [0.0.54] - 2025-09-25

### Changed

- Update CONTRIBUTING.md
- Refine `plan-template.md` with improved project type detection, clarified structure decision process, and enhanced research task guidance.
- Update __init__.py

## [0.0.53] - 2025-09-24

### Changed

- Update template path for spec file creation
- Update template path for spec file creation
- docs: remove constitution_update_checklist from README

## [0.0.52] - 2025-09-22

### Changed

- Update analyze.md
- Update templates/commands/analyze.md
- Update templates/commands/clarify.md
- Update templates/commands/plan.md
- Update with extra commands
- Update with --force flag
- feat: add uv tool install instructions to README

## [0.0.51] - 2025-09-21

### Changed

- Update with Roo Code support

## [0.0.50] - 2025-09-21

### Changed

- Update generate-release-notes.sh
- Update error messages
- Auggie folder fix

## [0.0.49] - 2025-09-21

### Changed

- Update scripts/powershell/update-agent-context.ps1
- Update templates/commands/implement.md
- Cleanup the check command
- Add support for Auggie
- Update AGENTS.md
- Updates with Kilo Code support
- Update README.md
- Update templates/commands/constitution.md
- Update templates/commands/implement.md
- Update templates/commands/plan.md
- Update templates/commands/specify.md
- Update templates/commands/tasks.md
- Update README.md
- Stop splitting the warning over multiple lines
- Update templates based on #419
- docs: Update README with codex in check command

## [0.0.48] - 2025-09-21

### Changed

- Update scripts/powershell/check-prerequisites.ps1
- Update CHANGELOG.md
- Update CHANGELOG.md
- Update changelog
- Update scripts/bash/update-agent-context.sh
- Fix script config
- Update scripts/bash/common.sh
- Update scripts/powershell/update-agent-context.ps1
- Update scripts/powershell/update-agent-context.ps1
- Clarification
- Update prompts
- Update update-agent-context.ps1
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update CONTRIBUTING.md
- Update contribution guidelines.
- Root detection logic
- Update templates/plan-template.md
- Update scripts/bash/update-agent-context.sh
- Update scripts/powershell/create-new-feature.ps1
- Simplification
- Script and template tweaks
- Update config
- Update scripts/powershell/check-prerequisites.ps1
- Update scripts/bash/check-prerequisites.sh
- Fix script path
- Script cleanup
- Update scripts/bash/check-prerequisites.sh
- Update scripts/powershell/check-prerequisites.ps1
- Update script delegation from GitHub Action
- Cleanup the setup for generated packages
- Use proper line endings
- Consolidate scripts

## [0.0.47] - 2025-09-20

### Changed

- Updating agent context files

## [0.0.46] - 2025-09-20

### Changed

- Update update-agent-context.ps1
- Update package release
- Update config
- Update __init__.py
- Update __init__.py
- Remove Codex-specific logic in the initialization script
- Update version rev
- Update __init__.py
- Enhance Codex support by auto-syncing prompt files, allowing spec generation without git, and documenting clearer /specify usage.
- Consistency tweaks
- Consistent step coloring
- Update __init__.py
- Update __init__.py
- Quick UI tweak
- Update package release
- Limit workspace command seeding to Codex init and update Codex documentation accordingly.
- Clarify Codex-specific README note with rationale for its different workflow.
- Bump to 0.0.7 and document Codex support
- Normalize Codex command templates to the scripts-based schema and auto-upgrade generated commands.
- Fix remaining merge conflict markers in __init__.py
- Add Codex CLI support with AGENTS.md and commands bootstrap

## [0.0.45] - 2025-09-19

### Changed

- Update with Windsurf support
- expose token as an argument through cli --github-token
- add github auth headers if there are GITHUB_TOKEN/GH_TOKEN set

## [0.0.44] - 2025-09-18

### Changed

- Update specify.md
- Update __init__.py

## [0.0.43] - 2025-09-18

### Changed

- Update with support for /implement

## [0.0.42] - 2025-09-18

### Changed

- Update constitution.md

## [0.0.41] - 2025-09-18

### Changed

- Update constitution.md

## [0.0.40] - 2025-09-18

### Changed

- Update constitution command

## [0.0.39] - 2025-09-18

### Changed

- Cleanup
- fix: commands format for qwen

## [0.0.38] - 2025-09-18

### Changed

- Fix template path in update-agent-context.sh
- docs: fix grammar mistakes in markdown files

## [0.0.37] - 2025-09-17

### Changed

- fix: add missing Qwen support to release workflow and agent scripts

## [0.0.36] - 2025-09-17

### Changed

- feat: Add opencode ai agent
- Fix --no-git argument resolution.

## [0.0.35] - 2025-09-17

### Changed

- chore(release): bump version to 0.0.5 and update changelog
- chore: address review feedback - remove comment and fix numbering
- feat: add Qwen Code support to Spec Kit

## [0.0.34] - 2025-09-15

### Changed

- Update template.

## [0.0.33] - 2025-09-15

### Changed

- Update scripts

## [0.0.32] - 2025-09-15

### Changed

- Update template paths

## [0.0.31] - 2025-09-15

### Changed

- Update for Cursor rules & script path
- Update Specify definition
- Update README.md
- Update with video header
- fix(docs): remove redundant white space

## [0.0.30] - 2025-09-12

### Changed

- Update update-agent-context.ps1

## [0.0.29] - 2025-09-12

### Changed

- Update create-release-packages.sh
- Update with check changes

## [0.0.28] - 2025-09-12

### Changed

- Update wording
- Update release.yml

## [0.0.27] - 2025-09-12

### Changed

- Support Cursor

## [0.0.26] - 2025-09-12

### Changed

- Saner approach to scripts

## [0.0.25] - 2025-09-12

### Changed

- Update packaging

## [0.0.24] - 2025-09-12

### Changed

- Fix package logic

## [0.0.23] - 2025-09-12

### Changed

- Update config
- Update __init__.py
- Refactor with platform-specific constraints
- Update README.md
- Update CLI reference
- Update __init__.py
- refactor: extract Claude local path to constant for maintainability
- fix: support Claude CLI installed via migrate-installer

## [0.0.22] - 2025-09-11

### Changed

- Update release.yml
- Update create-release-packages.sh
- Update create-release-packages.sh
- Update release file

## [0.0.21] - 2025-09-11

### Changed

- Consolidate script creation
- Update how Copilot prompts are created
- Update local-development.md
- Local dev guide and script updates
- Update CONTRIBUTING.md
- Enhance HTTP client initialization with optional SSL verification and bump version to 0.0.3
- Complete Gemini CLI command instructions
- Refactor HTTP client usage to utilize truststore for SSL context
- docs: Update Commands sections renaming to match implementation
- docs: Fix formatting issues in README.md for consistency
- Update docs and release

## [0.0.20] - 2025-09-08

### Changed

- Update docs/quickstart.md
- Docs setup

## [0.0.19] - 2025-09-08

### Changed

- Update README.md

## [0.0.18] - 2025-09-08

### Changed

- Update README.md

## [0.0.17] - 2025-09-08

### Changed

- Remove trailing whitespace from tasks.md template

## [0.0.16] - 2025-09-07

### Changed

- Fix release workflow to work with repository rules

## [0.0.15] - 2025-09-07

### Changed

- Use `/usr/bin/env bash` instead of `/bin/bash` for shebang

## [0.0.14] - 2025-09-04

### Changed

- fix: correct typos in spec-driven.md

## [0.0.13] - 2025-09-04

### Changed

- Fix formatting in usage instructions

## [0.0.12] - 2025-09-04

### Changed

- Fix template path in plan command documentation

## [0.0.11] - 2025-09-04

### Changed

- fix: incorrect tree structure in examples

## [0.0.10] - 2025-09-04

### Changed

- fix minor typo in Article I

## [0.0.9] - 2025-09-03

### Changed

- Update CLI commands from '/spec' to '/specify'

## [0.0.8] - 2025-09-02

### Changed

- adding executable permission to the scripts so they execute when the coding agent launches them

## [0.0.7] - 2025-09-02

### Changed

- doco(spec-driven): Fix small typo in document

## [0.0.6] - 2025-08-25

### Changed

- Update README.md

## [0.0.5] - 2025-08-25

### Changed

- Update .github/workflows/release.yml
- Fix release workflow to work with repository rules

## [0.0.4] - 2025-08-25

### Changed

- Add John Lam as contributor and release badge

## [0.0.3] - 2025-08-22

### Changed

- Update requirements

## [0.0.2] - 2025-08-22

### Changed

- Update README.md

## [0.0.1] - 2025-08-22

### Changed

- Update release.yml


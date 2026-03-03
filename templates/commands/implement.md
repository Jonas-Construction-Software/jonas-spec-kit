---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## Workspace Architecture Context

This command operates within the Spec Kit workspace architecture:

**Multi-Repository Workspace**:
- Reads tasks from `.specs/{feature-name}/tasks.md` in the `*-document` repository
- Creates matching feature branches in implementation repositories based on `[repo-name]` labels
- Executes tasks in their target repositories (switches context based on `[repo-name]`)
- Leaves all changes uncommitted across all affected repositories for user review

**Single-Repository Workspace**:
- Reads tasks from `.specs/{feature-name}/tasks.md` at repository root
- All tasks execute in the current repository (all `[repo-name]` labels are identical)
- No branch creation needed - work continues on current feature branch
- Leaves all changes uncommitted for user review

**Branch Strategy**:
- Multi-repo: Feature branch exists in `*-document` repo; implementation branches created in target repos by this command
- Single-repo: Single feature branch contains both planning artifacts and implementation code

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Multi-Repository Workspace Detection

**Before executing any tasks:**

1. **Parse Repository Labels**: Scan `tasks.md` for `[repo-name]` labels (mandatory for ALL tasks) to identify all repositories requiring changes
2. **Determine Implementation Scope**:
   - **Single-repo**: All `[repo-name]` labels reference the same repository
     - Work continues on the current branch in the active repository
     - No cross-repository coordination needed
   - **Multi-repo**: Multiple distinct `[repo-name]` labels found across tasks
     - Create matching feature branches in all affected repositories
     - Coordinate work across repository boundaries
3. **Branch Strategy**:
   - **Single-repo**: Work continues on the current branch in the active repository
   - **Multi-repo**: Create matching feature branches in all affected repositories using the same branch name as the `*-document` repository

## Outline

0. **Multi-Repository Branch Setup**:
   
   Run the branch setup script from repo root:
   
   **Bash:**
   ```bash
   .specify/scripts/bash/setup-repo-branches.sh
   ```
   
   **PowerShell:**
   ```powershell
   .specify/scripts/powershell/setup-repo-branches.ps1
   ```
   
   This script will:
   
   a. **Detect workspace structure**:
      - Check for multiple `.git` directories in sibling folders
      - Identify the active repository from `FEATURE_DIR` path
      - Extract the current branch name from the `*-document` repository
   
   b. **Parse implementation repositories** from `tasks.md`:
      - Scan all task descriptions for `[repo-name]` labels
      - Build unique list of repositories requiring implementation changes
      - Compare against workspace repository list
   
   c. **Create feature branches** in implementation repositories:
      - For each affected repository (excluding `*-document`):
        - Navigate to repository root
        - Check if feature branch already exists
        - If not, create a new branch with the same name as the `*-document` branch
        - Verify branch creation was successful
        - Return to the appropriate repository for task execution
      - Report created branches to user
   
   d. **Single-repo scenario handling**:
      - If no `[repo-name]` labels found in tasks, the script reports single-repo scenario
      - If all `[repo-name]` labels reference the current repository, treated as single-repo
      - If feature branches already exist in all affected repositories, the script reports this
   
   **Note**: The script handles both multi-repo and single-repo scenarios automatically. For single-repo projects, it simply reports that no cross-repository work is needed and exits successfully.

1. **Setup**: Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Repository context switching** (multi-repo only):
     - Before executing tasks with `[repo-name]` labels, navigate to the appropriate repository
     - Verify the correct feature branch is checked out
     - Execute the task in the target repository's context
     - Return to the previous working directory after completion
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together  
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding
   - **Cross-repository coordination**: For tasks spanning multiple repositories, ensure contract compatibility and integration points align

7. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

8. Progress tracking and error handling:
   - Report progress after each completed task
   - **Multi-repo**: Include repository name in progress updates for cross-repo tasks
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - **Multi-repo**: If a task fails in a specific repository, clearly indicate which repository and provide repository-specific debugging context
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, mark the task as [X] in the tasks file
   - **Multi-repo**: Ensure task completion markers are updated regardless of which repository the task executed in

9. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - **DO NOT commit changes** - leave all changes uncommitted (staged or unstaged) for user review
   - Report final status with summary of completed work in the chat (do not create additional files)

10. **Multi-Repository Completion Validation** (if multi-repo workspace):
    - Verify all affected repositories have matching feature branches
    - Confirm all cross-repository tasks completed successfully
    - Validate contract compatibility across repository boundaries
    - **DO NOT commit changes in any repository** - leave all changes uncommitted for user review
    - Report which repositories have uncommitted changes
    - Recommend coordination steps for pull request creation across repositories:
      - Create PRs in dependency order (shared contracts → consumers)
      - Link related PRs across repositories
      - Coordinate merge timing to avoid breaking changes

**IMPORTANT**: Do NOT commit any changes. All changes must remain uncommitted (staged or unstaged) for user review before committing. This applies to both single-repository and multi-repository implementations.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.

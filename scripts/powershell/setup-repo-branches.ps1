#!/usr/bin/env pwsh
# Setup feature branches in multi-repo workspace based on tasks.md repository labels
#
# This script:
# 1. Parses tasks.md for [repo-name] labels to identify affected repositories
# 2. Creates matching feature branches in implementation repositories
# 3. Uses the same branch name as the *-document repository
#
# Usage:
#   .\setup-repo-branches.ps1
#
# Environment:
#   Requires common.ps1 for Get-FeaturePathsEnv() function
#
# Exit Codes:
#   0 - Success (branches created or already exist)
#   1 - Error (missing tasks.md, git errors, etc.)

param()

$ErrorActionPreference = 'Stop'

# Load common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

# Get feature paths
$envData = Get-FeaturePathsEnv
$REPO_ROOT = $envData.REPO_ROOT
$CURRENT_BRANCH = $envData.CURRENT_BRANCH
$TASKS = $envData.TASKS

# Verify tasks.md exists
if (-not (Test-Path $TASKS)) {
    Write-Error "ERROR: tasks.md not found at $TASKS"
    Write-Error "Please run /speckit.tasks first to generate the task breakdown."
    exit 1
}

# Extract unique repository names from tasks.md
# Format: - [ ] [TaskID] [P?] [Story?] [Repo] Description
# The [Repo] label is mandatory and is the last label before the description
# We filter out system labels: P, US#, T#
$taskLines = Select-String -Path $TASKS -Pattern '^\s*-\s*\[\s*\]\s*T\d+' | ForEach-Object { $_.Line }
$repos = @()

foreach ($line in $taskLines) {
    # Extract all bracketed labels
    $labels = [regex]::Matches($line, '\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }
    
    # Filter out known non-repo labels (P, US#, T#) and take the last remaining one
    $repoLabel = $labels | Where-Object { $_ -notmatch '^(P|US\d+|T\d+)$' } | Select-Object -Last 1
    
    if ($repoLabel) {
        $repos += $repoLabel
    }
}

$repos = $repos | Sort-Object -Unique

# If no repository labels found, tasks.md format is incorrect
if (-not $repos -or $repos.Count -eq 0) {
    Write-Error "No repository labels found in tasks.md. Each task must have a [repo-name] label."
    exit 1
}

# Get the parent directory of the current repository (workspace root)
$WORKSPACE_ROOT = Split-Path -Parent $REPO_ROOT

# Get current repository name
$CURRENT_REPO = Split-Path -Leaf $REPO_ROOT

# Check if all repository labels reference only the current repository
$otherRepos = $repos | Where-Object { $_ -ne $CURRENT_REPO }
if (-not $otherRepos -or $otherRepos.Count -eq 0) {
    Write-Host "✓ Single-repository scenario detected (all [repo-name] labels reference current repository)" -ForegroundColor Green
    Write-Host "  Implementation will proceed in the current repository: $CURRENT_REPO"
    exit 0
}

# Track if any branches were created
$branchesCreated = $false
$branchesExisted = $false
$reposAffected = @()

Write-Host "Multi-repository workspace detected" -ForegroundColor Cyan
Write-Host "Current branch: $CURRENT_BRANCH"
Write-Host "Repositories requiring changes:"

# For each repository, create matching branch
foreach ($repo in $repos) {
    if ([string]::IsNullOrWhiteSpace($repo)) {
        continue
    }
    
    $repoPath = Join-Path $WORKSPACE_ROOT $repo
    
    # Check if repository exists
    if (-not (Test-Path (Join-Path $repoPath '.git'))) {
        Write-Host "  ⚠  [$repo] - Repository not found at $repoPath" -ForegroundColor Yellow
        continue
    }
    
    # Skip if this is the document repository (branch already created via /speckit.specify)
    if ($repo -like "*-document") {
        Write-Host "  ⏭️  [$repo] - Skipping (document repository - branch already created)" -ForegroundColor Gray
        continue
    }
    
    # Navigate to repository
    Push-Location $repoPath
    
    try {
        # Check if branch exists
        $branchExists = $null
        try {
            $branchExists = git rev-parse --verify $CURRENT_BRANCH 2>$null
        }
        catch {
            $branchExists = $null
        }
        
        if ($LASTEXITCODE -eq 0 -and $branchExists) {
            Write-Host "  ✓ [$repo] - Branch '$CURRENT_BRANCH' already exists" -ForegroundColor Green
            $branchesExisted = $true
        }
        else {
            # Create the branch
            $output = git checkout -b $CURRENT_BRANCH 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ [$repo] - Created branch '$CURRENT_BRANCH'" -ForegroundColor Green
                $branchesCreated = $true
            }
            else {
                Write-Host "  ✗ [$repo] - Failed to create branch '$CURRENT_BRANCH'" -ForegroundColor Red
                Write-Error $output
                continue
            }
        }
        
        $reposAffected += $repo
    }
    finally {
        # Return to original directory
        Pop-Location
    }
}

# Return to the feature repository
try {
    Set-Location $REPO_ROOT
}
catch {
    # Ignore errors when returning to repo root
}

# Summary
Write-Host ""
if ($reposAffected.Count -eq 0) {
    Write-Host "⚠  No repositories were affected" -ForegroundColor Yellow
    Write-Host "   Please verify [repo-name] labels in tasks.md match actual repository names"
}
elseif ($branchesCreated) {
    Write-Host "✓ Multi-repository branch setup complete" -ForegroundColor Green
    Write-Host "  Affected repositories: $($reposAffected -join ', ')"
    Write-Host "  Ready to proceed with cross-repository implementation"
}
elseif ($branchesExisted) {
    Write-Host "✓ All required branches already exist" -ForegroundColor Green
    Write-Host "  Affected repositories: $($reposAffected -join ', ')"
}

exit 0

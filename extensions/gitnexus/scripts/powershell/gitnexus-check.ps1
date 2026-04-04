# GitNexus Runtime Guard (PowerShell)
#
# Fast, non-blocking check before any GitNexus tool call.
# Designed to be called from enrichment command preambles.
#
# Usage:
#   gitnexus-check.ps1 [-Strict] [-Json] [[-RepoPath] <path>]
#
# Options:
#   -Strict    Use stricter staleness threshold (warn_at_commits, default 5)
#   -Json      Output in JSON format
#   -RepoPath  Path to check (defaults to git root of current directory)
#
# Exit codes:
#   0  Index found, not stale
#   1  Index not found (.gitnexus/meta.json missing)
#   2  Index stale (commits behind >= threshold)
#   3  Repository is a *-document repo (planning artifacts only) - skip silently

param(
    [switch]$Strict,
    [switch]$Json,
    [string]$RepoPath,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: gitnexus-check.ps1 [-Strict] [-Json] [[-RepoPath] <path>]"
    exit 0
}

# Resolve repo path
if (-not $RepoPath) {
    $RepoPath = try { git rev-parse --show-toplevel 2>$null } catch { $PWD.Path }
    if (-not $RepoPath) { $RepoPath = $PWD.Path }
}

# Skip *-document repositories - these hold planning artifacts, not source code
$repoName = Split-Path $RepoPath -Leaf
if ($repoName -like '*-document') {
    if ($Json) {
        @{
            status  = "skipped"
            reason  = "document-repo"
            repo    = $RepoPath
            message = "*-document repositories hold planning artifacts only and are not indexed by GitNexus."
        } | ConvertTo-Json -Compress
    } else {
        Write-Host "[SKIP] Skipping *-document repository: $repoName (planning artifacts only)"
    }
    exit 3
}

# Read config thresholds
$defaultThreshold = 10
$strictThreshold = 5
$configFile = Join-Path (Join-Path (Join-Path (Join-Path $RepoPath ".specify") "extensions") "gitnexus") "gitnexus-config.yml"

if (Test-Path $configFile) {
    $configContent = Get-Content $configFile -Raw
    if ($configContent -match 'threshold_commits:\s*(\d+)') {
        $defaultThreshold = [int]$Matches[1]
    }
    if ($configContent -match 'warn_at_commits:\s*(\d+)') {
        $strictThreshold = [int]$Matches[1]
    }
}

$threshold = if ($Strict) { $strictThreshold } else { $defaultThreshold }

# --- Check 1: Index existence ---
$metaFile = Join-Path (Join-Path $RepoPath ".gitnexus") "meta.json"

if (-not (Test-Path $metaFile)) {
    if ($Json) {
        @{
            status  = "no-index"
            repo    = $RepoPath
            message = "GitNexus index not found. Run /speckit.gitnexus.setup to index this repository."
        } | ConvertTo-Json -Compress
    } else {
        Write-Host "[WARN] GitNexus index not found at $RepoPath"
        Write-Host "   Run /speckit.gitnexus.setup to index this repository."
    }
    exit 1
}

# --- Check 2: Staleness ---
$commitsBehind = 0
try {
    $metaContent = Get-Content $metaFile -Raw | ConvertFrom-Json
    $lastCommit = $metaContent.lastCommit
    if ($lastCommit) {
        $result = git -C $RepoPath rev-list --count "$lastCommit..HEAD" 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) {
            $commitsBehind = [int]$result.Trim()
        }
    }
} catch {
    # Fail-open: treat as not stale
    $commitsBehind = 0
}

if ($commitsBehind -ge $threshold) {
    if ($Json) {
        @{
            status         = "stale"
            repo           = $RepoPath
            commits_behind = $commitsBehind
            threshold      = $threshold
            message        = "Index is $commitsBehind commits behind HEAD. Run npx gitnexus analyze to update."
        } | ConvertTo-Json -Compress
    } else {
        Write-Host "[WARN] GitNexus index is $commitsBehind commits behind HEAD (threshold: $threshold)"
        Write-Host "   Run: npx gitnexus analyze"
    }
    exit 2
}

# --- All good ---
if ($Json) {
    @{
        status         = "ready"
        repo           = $RepoPath
        commits_behind = $commitsBehind
        threshold      = $threshold
    } | ConvertTo-Json -Compress
} else {
    Write-Host "[OK] GitNexus index is ready ($commitsBehind commits behind HEAD)"
}
exit 0

# GitNexus Setup Helper Script (PowerShell)
#
# Usage:
#   gitnexus-setup.ps1 -Check     Check if GitNexus CLI is installed
#   gitnexus-setup.ps1 -Verify    Verify full setup state (CLI + MCP + index)
#   gitnexus-setup.ps1 -Json      Output in JSON format (combine with -Check or -Verify)
#
# Exit codes:
#   0  All checks passed
#   1  GitNexus CLI not found
#   2  Partial setup (CLI found but MCP or index missing)

param(
    [switch]$Check,
    [switch]$Verify,
    [switch]$Json,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: gitnexus-setup.ps1 [-Check|-Verify] [-Json]"
    Write-Host "  -Check   Check if GitNexus CLI is installed"
    Write-Host "  -Verify  Verify full setup state"
    Write-Host "  -Json    Output in JSON format"
    exit 0
}

if (-not $Check -and -not $Verify) {
    Write-Error "Specify -Check or -Verify. Use -Help for usage."
    exit 1
}

# --- Helper functions ---

function Test-GitNexusCli {
    $version = $null
    $status = "not-found"

    try {
        $version = & gitnexus --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $version) {
            $status = "installed"
        }
    } catch { }

    if ($status -eq "not-found") {
        try {
            $version = & npx -y gitnexus@latest --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $version) {
                $status = "available-via-npx"
            }
        } catch { }
    }

    return @{ Status = $status; Version = if ($version) { $version.Trim() } else { "" } }
}

function Test-McpConfig {
    # Check user-level mcp.json first (recommended for GitNexus global setup)
    $userMcpFile = Join-Path (Join-Path (Join-Path $env:APPDATA "Code") "User") "mcp.json"

    if (Test-Path $userMcpFile) {
        $content = Get-Content $userMcpFile -Raw
        if ($content -match '"gitnexus"') {
            return "configured"
        }
    }

    # Fall back to workspace-level .vscode/mcp.json
    $workspaceRoot = try { git rev-parse --show-toplevel 2>$null } catch { $PWD.Path }
    if (-not $workspaceRoot) { $workspaceRoot = $PWD.Path }

    $mcpFile = Join-Path (Join-Path $workspaceRoot ".vscode") "mcp.json"

    if (Test-Path $mcpFile) {
        $content = Get-Content $mcpFile -Raw
        if ($content -match '"gitnexus"') {
            return "configured"
        }
        return "missing-gitnexus-entry"
    }
    return "no-mcp-file"
}

function Test-GitNexusIndex {
    $workspaceRoot = try { git rev-parse --show-toplevel 2>$null } catch { $PWD.Path }
    if (-not $workspaceRoot) { $workspaceRoot = $PWD.Path }

    $metaFile = Join-Path (Join-Path $workspaceRoot ".gitnexus") "meta.json"

    if (Test-Path $metaFile) {
        return "indexed"
    }
    return "not-indexed"
}

# --- Actions ---

if ($Check) {
    $cli = Test-GitNexusCli

    if ($Json) {
        $result = @{
            cli_status = $cli.Status
            version    = $cli.Version
        }
        $result | ConvertTo-Json -Compress
    } else {
        Write-Host "GitNexus CLI: $($cli.Status)"
        if ($cli.Version) {
            Write-Host "Version: $($cli.Version)"
        }
    }

    if ($cli.Status -eq "not-found") { exit 1 }
    exit 0
}

if ($Verify) {
    $cli = Test-GitNexusCli
    $mcpStatus = Test-McpConfig
    $indexStatus = Test-GitNexusIndex

    $allOk = ($cli.Status -ne "not-found") -and ($mcpStatus -eq "configured") -and ($indexStatus -eq "indexed")

    if ($Json) {
        $result = @{
            cli_status   = $cli.Status
            version      = $cli.Version
            mcp_status   = $mcpStatus
            index_status = $indexStatus
            all_ok       = $allOk
        }
        $result | ConvertTo-Json -Compress
    } else {
        Write-Host "GitNexus CLI: $($cli.Status)"
        if ($cli.Version) {
            Write-Host "Version: $($cli.Version)"
        }
        Write-Host "MCP Config: $mcpStatus"
        Write-Host "Index: $indexStatus"
        Write-Host ""
        if ($allOk) {
            Write-Host "[OK] All checks passed"
        } else {
            Write-Host "[WARN] Some checks failed - run /speckit.gitnexus.setup to fix"
        }
    }

    if ($cli.Status -eq "not-found") { exit 1 }
    if (-not $allOk) { exit 2 }
    exit 0
}

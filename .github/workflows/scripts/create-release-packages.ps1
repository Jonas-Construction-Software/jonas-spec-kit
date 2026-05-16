#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Build Spec Kit template release archives for each supported AI assistant and script type.

.DESCRIPTION
    create-release-packages.ps1 (workflow-local)
    Build Spec Kit template release archives for each supported AI assistant and script type.

.PARAMETER Version
    Version string with leading 'v' (e.g., v0.2.0)

.PARAMETER Agents
    Comma or space separated subset of agents to build (default: all)
    Valid agents: claude, gemini, copilot, cursor-agent, qwen, opencode, windsurf, junie, codex, kilocode, auggie, roo, codebuddy, amp, kiro-cli, bob, qodercli, shai, tabnine, agy, vibe, kimi, trae, pi, iflow, generic

.PARAMETER Scripts
    Comma or space separated subset of script types to build (default: both)
    Valid scripts: sh, ps

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0 -Agents claude,copilot -Scripts sh

.EXAMPLE
    .\create-release-packages.ps1 -Version v0.2.0 -Agents claude -Scripts ps
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$Agents = "",

    [Parameter(Mandatory=$false)]
    [string]$Scripts = ""
)

$ErrorActionPreference = "Stop"

# Validate version format
if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Error "Version must look like v0.0.0"
    exit 1
}

Write-Host "Building release packages for $Version"

# Create and use .genreleases directory for all build artifacts
$GenReleasesDir = ".genreleases"
if (Test-Path $GenReleasesDir) {
    Remove-Item -Path $GenReleasesDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $GenReleasesDir -Force | Out-Null

function Rewrite-Paths {
    param([string]$Content)

    $Content = $Content -replace '(/?)\bmemory/', '.specify/memory/'
    $Content = $Content -replace '(/?)\bscripts/', '.specify/scripts/'
    $Content = $Content -replace '(/?)\btemplates/', '.specify/templates/'
    return $Content
}

function Generate-Commands {
    param(
        [string]$Agent,
        [string]$Extension,
        [string]$ArgFormat,
        [string]$OutputDir,
        [string]$ScriptVariant
    )

    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    $templates = Get-ChildItem -Path "templates/commands/*.md" -File -ErrorAction SilentlyContinue

    foreach ($template in $templates) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)

        # Read file content and normalize line endings
        $fileContent = (Get-Content -Path $template.FullName -Raw) -replace "`r`n", "`n"

        # Extract description from YAML frontmatter
        $description = ""
        if ($fileContent -match '(?m)^description:\s*(.+)$') {
            $description = $matches[1]
        }

        # Extract script command from YAML frontmatter
        $scriptCommand = ""
        if ($fileContent -match "(?m)^\s*${ScriptVariant}:\s*(.+)$") {
            $scriptCommand = $matches[1]
        }

        if ([string]::IsNullOrEmpty($scriptCommand)) {
            Write-Warning "No script command found for $ScriptVariant in $($template.Name)"
            $scriptCommand = "(Missing script command for $ScriptVariant)"
        }

        # Extract agent_script command from YAML frontmatter if present
        $agentScriptCommand = ""
        if ($fileContent -match "(?ms)agent_scripts:.*?^\s*${ScriptVariant}:\s*(.+?)$") {
            $agentScriptCommand = $matches[1].Trim()
        }

        # Replace {SCRIPT} placeholder with the script command
        $body = $fileContent -replace '\{SCRIPT\}', $scriptCommand

        # Replace {AGENT_SCRIPT} placeholder with the agent script command if found
        if (-not [string]::IsNullOrEmpty($agentScriptCommand)) {
            $body = $body -replace '\{AGENT_SCRIPT\}', $agentScriptCommand
        }

        # Remove the scripts: and agent_scripts: sections from frontmatter
        $lines = $body -split "`n"
        $outputLines = @()
        $inFrontmatter = $false
        $skipScripts = $false
        $dashCount = 0

        foreach ($line in $lines) {
            if ($line -match '^---$') {
                $outputLines += $line
                $dashCount++
                if ($dashCount -eq 1) {
                    $inFrontmatter = $true
                } else {
                    $inFrontmatter = $false
                }
                continue
            }

            if ($inFrontmatter) {
                if ($line -match '^(scripts|agent_scripts):$') {
                    $skipScripts = $true
                    continue
                }
                if ($line -match '^[a-zA-Z].*:' -and $skipScripts) {
                    $skipScripts = $false
                }
                if ($skipScripts -and $line -match '^\s+') {
                    continue
                }
            }

            $outputLines += $line
        }

        $body = $outputLines -join "`n"

        # Apply other substitutions
        $body = $body -replace '\{ARGS\}', $ArgFormat
        $body = $body -replace '__AGENT__', $Agent
        $body = Rewrite-Paths -Content $body

        # Generate output file based on extension
        $outputFile = Join-Path $OutputDir "speckit.$name.$Extension"

        switch ($Extension) {
            'toml' {
                $body = $body -replace '\\', '\\'
                $output = "description = `"$description`"`n`nprompt = `"`"`"`n$body`n`"`"`""
                Set-Content -Path $outputFile -Value $output -NoNewline
            }
            'md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
            'agent.md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
        }
    }
}

function Generate-CopilotPrompts {
    param(
        [string]$AgentsDir,
        [string]$PromptsDir
    )

    New-Item -ItemType Directory -Path $PromptsDir -Force | Out-Null

    $agentFiles = Get-ChildItem -Path "$AgentsDir/speckit.*.agent.md" -File -ErrorAction SilentlyContinue

    foreach ($agentFile in $agentFiles) {
        $basename = $agentFile.Name -replace '\.agent\.md$', ''
        $promptFile = Join-Path $PromptsDir "$basename.prompt.md"

        $content = @"
---
agent: $basename
---
"@
        Set-Content -Path $promptFile -Value $content
    }
}

# Create skills in <skills_dir>\<name>\SKILL.md format.
# Most agents use hyphenated names (e.g. speckit-plan); Kimi is the
# current dotted-name exception (e.g. speckit.plan).
#
# Technical debt note:
# Keep SKILL.md frontmatter aligned with `install_ai_skills()` and extension
# overrides (at minimum: name/description/compatibility/metadata.{author,source}).
function New-Skills {
    param(
        [string]$SkillsDir,
        [string]$ScriptVariant,
        [string]$AgentName,
        [string]$Separator = '-'
    )

    $templates = Get-ChildItem -Path "templates/commands/*.md" -File -ErrorAction SilentlyContinue

    foreach ($template in $templates) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)
        $skillName = "speckit${Separator}$name"
        $skillDir = Join-Path $SkillsDir $skillName
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null

        $fileContent = (Get-Content -Path $template.FullName -Raw) -replace "`r`n", "`n"

        # Extract description
        $description = "Spec Kit: $name workflow"
        if ($fileContent -match '(?m)^description:\s*(.+)$') {
            $description = $matches[1]
        }

        # Extract script command
        $scriptCommand = "(Missing script command for $ScriptVariant)"
        if ($fileContent -match "(?m)^\s*${ScriptVariant}:\s*(.+)$") {
            $scriptCommand = $matches[1]
        }

        # Extract agent_script command from frontmatter if present
        $agentScriptCommand = ""
        if ($fileContent -match "(?ms)agent_scripts:.*?^\s*${ScriptVariant}:\s*(.+?)$") {
            $agentScriptCommand = $matches[1].Trim()
        }

        # Replace {SCRIPT}, strip scripts sections, rewrite paths
        $body = $fileContent -replace '\{SCRIPT\}', $scriptCommand
        if (-not [string]::IsNullOrEmpty($agentScriptCommand)) {
            $body = $body -replace '\{AGENT_SCRIPT\}', $agentScriptCommand
        }

        $lines = $body -split "`n"
        $outputLines = @()
        $inFrontmatter = $false
        $skipScripts = $false
        $dashCount = 0

        foreach ($line in $lines) {
            if ($line -match '^---$') {
                $outputLines += $line
                $dashCount++
                $inFrontmatter = ($dashCount -eq 1)
                continue
            }
            if ($inFrontmatter) {
                if ($line -match '^(scripts|agent_scripts):$') { $skipScripts = $true; continue }
                if ($line -match '^[a-zA-Z].*:' -and $skipScripts) { $skipScripts = $false }
                if ($skipScripts -and $line -match '^\s+') { continue }
            }
            $outputLines += $line
        }

        $body = $outputLines -join "`n"
        $body = $body -replace '\{ARGS\}', '$ARGUMENTS'
        $body = $body -replace '__AGENT__', $AgentName
        $body = Rewrite-Paths -Content $body

        # Strip existing frontmatter, keep only body
        $templateBody = ""
        $fmCount = 0
        $inBody = $false
        foreach ($line in ($body -split "`n")) {
            if ($line -match '^---$') {
                $fmCount++
                if ($fmCount -eq 2) { $inBody = $true }
                continue
            }
            if ($inBody) { $templateBody += "$line`n" }
        }

        $skillContent = "---`nname: `"$skillName`"`ndescription: `"$description`"`ncompatibility: `"Requires spec-kit project structure with .specify/ directory`"`nmetadata:`n  author: `"github-spec-kit`"`n  source: `"templates/commands/$name.md`"`n---`n`n$templateBody"
        Set-Content -Path (Join-Path $skillDir "SKILL.md") -Value $skillContent -NoNewline
    }
}

function Build-Variant {
    param(
        [string]$Agent,
        [string]$Script
    )

    $baseDir = Join-Path $GenReleasesDir "sdd-${Agent}-package-${Script}"
    Write-Host "Building $Agent ($Script) package..."
    New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

    # Copy base structure but filter scripts by variant
    $specDir = Join-Path $baseDir ".specify"
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null

    # Copy memory directory
    if (Test-Path "memory") {
        Copy-Item -Path "memory" -Destination $specDir -Recurse -Force
        Write-Host "Copied memory -> .specify"
    }

    # Only copy the relevant script variant directory
    if (Test-Path "scripts") {
        $scriptsDestDir = Join-Path $specDir "scripts"
        New-Item -ItemType Directory -Path $scriptsDestDir -Force | Out-Null

        switch ($Script) {
            'sh' {
                if (Test-Path "scripts/bash") {
                    Copy-Item -Path "scripts/bash" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "Copied scripts/bash -> .specify/scripts"
                }
            }
            'ps' {
                if (Test-Path "scripts/powershell") {
                    Copy-Item -Path "scripts/powershell" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "Copied scripts/powershell -> .specify/scripts"
                }
            }
        }

        Get-ChildItem -Path "scripts" -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $scriptsDestDir -Force
        }
    }

    # Copy templates (excluding commands directory and vscode-settings.json)
    if (Test-Path "templates") {
        $templatesDestDir = Join-Path $specDir "templates"
        New-Item -ItemType Directory -Path $templatesDestDir -Force | Out-Null

        Get-ChildItem -Path "templates" -Recurse -File | Where-Object {
            $_.FullName -notmatch 'templates[/\\]commands[/\\]' -and $_.Name -ne 'vscode-settings.json'
        } | ForEach-Object {
            $relativePath = $_.FullName.Substring((Resolve-Path "templates").Path.Length + 1)
            $destFile = Join-Path $templatesDestDir $relativePath
            $destFileDir = Split-Path $destFile -Parent
            New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null
            Copy-Item -Path $_.FullName -Destination $destFile -Force
        }
        Write-Host "Copied templates -> .specify/templates"
    }

    # Generate agent-specific command files
    switch ($Agent) {
        'claude' {
            $cmdDir = Join-Path $baseDir ".claude/commands"
            Generate-Commands -Agent 'claude' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'gemini' {
            $cmdDir = Join-Path $baseDir ".gemini/commands"
            Generate-Commands -Agent 'gemini' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/gemini/GEMINI.md") {
                Copy-Item -Path "agent_templates/gemini/GEMINI.md" -Destination (Join-Path $baseDir "GEMINI.md")
            }
        }
        'copilot' {
            $agentsDir = Join-Path $baseDir ".github/agents"
            Generate-Commands -Agent 'copilot' -Extension 'agent.md' -ArgFormat '$ARGUMENTS' -OutputDir $agentsDir -ScriptVariant $Script

            $promptsDir = Join-Path $baseDir ".github/prompts"
            Generate-CopilotPrompts -AgentsDir $agentsDir -PromptsDir $promptsDir

            $vscodeDir = Join-Path $baseDir ".vscode"
            New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
            if (Test-Path "templates/vscode-settings.json") {
                Copy-Item -Path "templates/vscode-settings.json" -Destination (Join-Path $vscodeDir "settings.json")
            }
        }
        'cursor-agent' {
            $cmdDir = Join-Path $baseDir ".cursor/commands"
            Generate-Commands -Agent 'cursor-agent' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qwen' {
            $cmdDir = Join-Path $baseDir ".qwen/commands"
            Generate-Commands -Agent 'qwen' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/qwen/QWEN.md") {
                Copy-Item -Path "agent_templates/qwen/QWEN.md" -Destination (Join-Path $baseDir "QWEN.md")
            }
        }
        'opencode' {
            $cmdDir = Join-Path $baseDir ".opencode/command"
            Generate-Commands -Agent 'opencode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'windsurf' {
            $cmdDir = Join-Path $baseDir ".windsurf/workflows"
            Generate-Commands -Agent 'windsurf' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'junie' {
            $cmdDir = Join-Path $baseDir ".junie/commands"
            Generate-Commands -Agent 'junie' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codex' {
            $skillsDir = Join-Path $baseDir ".agents/skills"
            New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
            New-Skills -SkillsDir $skillsDir -ScriptVariant $Script -AgentName 'codex' -Separator '-'
        }
        'kilocode' {
            $cmdDir = Join-Path $baseDir ".kilocode/workflows"
            Generate-Commands -Agent 'kilocode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'auggie' {
            $cmdDir = Join-Path $baseDir ".augment/commands"
            Generate-Commands -Agent 'auggie' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'roo' {
            $cmdDir = Join-Path $baseDir ".roo/commands"
            Generate-Commands -Agent 'roo' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codebuddy' {
            $cmdDir = Join-Path $baseDir ".codebuddy/commands"
            Generate-Commands -Agent 'codebuddy' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'amp' {
            $cmdDir = Join-Path $baseDir ".agents/commands"
            Generate-Commands -Agent 'amp' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'kiro-cli' {
            $cmdDir = Join-Path $baseDir ".kiro/prompts"
            Generate-Commands -Agent 'kiro-cli' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'bob' {
            $cmdDir = Join-Path $baseDir ".bob/commands"
            Generate-Commands -Agent 'bob' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qodercli' {
            $cmdDir = Join-Path $baseDir ".qoder/commands"
            Generate-Commands -Agent 'qodercli' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'shai' {
            $cmdDir = Join-Path $baseDir ".shai/commands"
            Generate-Commands -Agent 'shai' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'tabnine' {
            $cmdDir = Join-Path $baseDir ".tabnine/agent/commands"
            Generate-Commands -Agent 'tabnine' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            $tabnineTemplate = Join-Path 'agent_templates' 'tabnine/TABNINE.md'
            if (Test-Path $tabnineTemplate) { Copy-Item $tabnineTemplate (Join-Path $baseDir 'TABNINE.md') }
        }
        'agy' {
            $cmdDir = Join-Path $baseDir ".agent/commands"
            Generate-Commands -Agent 'agy' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'vibe' {
            $cmdDir = Join-Path $baseDir ".vibe/prompts"
            Generate-Commands -Agent 'vibe' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'kimi' {
            $skillsDir = Join-Path $baseDir ".kimi/skills"
            New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
            New-Skills -SkillsDir $skillsDir -ScriptVariant $Script -AgentName 'kimi' -Separator '.'
        }
        'trae' {
            $rulesDir = Join-Path $baseDir ".trae/rules"
            New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
            Generate-Commands -Agent 'trae' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $rulesDir -ScriptVariant $Script
        }
        'pi' {
            $cmdDir = Join-Path $baseDir ".pi/prompts"
            Generate-Commands -Agent 'pi' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'iflow' {
            $cmdDir = Join-Path $baseDir ".iflow/commands"
            Generate-Commands -Agent 'iflow' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'generic' {
            $cmdDir = Join-Path $baseDir ".speckit/commands"
            Generate-Commands -Agent 'generic' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        default {
            throw "Unsupported agent '$Agent'."
        }
    }

    # Create zip archive
    $zipFile = Join-Path $GenReleasesDir "spec-kit-template-${Agent}-${Script}-${Version}.zip"
    Compress-Archive -Path "$baseDir/*" -DestinationPath $zipFile -Force
    Write-Host "Created $zipFile"
}

# Define all agents and scripts
$AllAgents = @('claude', 'gemini', 'copilot', 'cursor-agent', 'qwen', 'opencode', 'windsurf', 'junie', 'codex', 'kilocode', 'auggie', 'roo', 'codebuddy', 'amp', 'kiro-cli', 'bob', 'qodercli', 'shai', 'tabnine', 'agy', 'vibe', 'kimi', 'trae', 'pi', 'iflow', 'generic')
$AllScripts = @('sh', 'ps')

function Normalize-List {
    param([string]$RawList)

    if ([string]::IsNullOrEmpty($RawList)) {
        return @()
    }

    $items = $RawList -split '[,\s]+' | Where-Object { $_ } | Select-Object -Unique
    return $items
}

function Validate-Subset {
    param(
        [string]$Type,
        [string[]]$Allowed,
        [string[]]$Items
    )

    $ok = $true
    foreach ($item in $Items) {
        if ($item -notin $Allowed) {
            Write-Error "Unknown $Type '$item' (allowed: $($Allowed -join ', '))"
            $ok = $false
        }
    }
    return $ok
}

# Determine agent list
if (-not [string]::IsNullOrEmpty($Agents)) {
    $AgentList = Normalize-List -RawList $Agents
    if (-not (Validate-Subset -Type 'agent' -Allowed $AllAgents -Items $AgentList)) {
        exit 1
    }
} else {
    $AgentList = $AllAgents
}

# Determine script list
if (-not [string]::IsNullOrEmpty($Scripts)) {
    $ScriptList = Normalize-List -RawList $Scripts
    if (-not (Validate-Subset -Type 'script' -Allowed $AllScripts -Items $ScriptList)) {
        exit 1
    }
} else {
    $ScriptList = $AllScripts
}

Write-Host "Agents: $($AgentList -join ', ')"
Write-Host "Scripts: $($ScriptList -join ', ')"

# Build all variants
foreach ($agent in $AgentList) {
    foreach ($script in $ScriptList) {
        Build-Variant -Agent $agent -Script $script
    }
}

Write-Host "`nArchives in ${GenReleasesDir}:"
Get-ChildItem -Path $GenReleasesDir -Filter "spec-kit-template-*-${Version}.zip" | ForEach-Object {
    Write-Host "  $($_.Name)"
}

# SIG # Begin signature block
# MIIodwYJKoZIhvcNAQcCoIIoaDCCKGQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1bZjRkjxKIthk
# AtWchVxIebPTLIdy8ZcGqGQE1MRE/6CCDawwggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggb0MIIE3KADAgECAhABjTK05HKmJmJ8uUcHkB9WMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjQwMjA3MDAwMDAwWhcNMjcwMjA5
# MjM1OTU5WjB8MQswCQYDVQQGEwJDQTEQMA4GA1UECBMHT250YXJpbzETMBEGA1UE
# BxMKVW5pb252aWxsZTEiMCAGA1UEChMZR2FyeSBKb25hcyBDb21wdXRpbmcgTHRk
# LjEiMCAGA1UEAxMZR2FyeSBKb25hcyBDb21wdXRpbmcgTHRkLjCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBANaSUvcW8AP6keeu5ls6CEKy6ojrK3cIvwZH
# 8ZaAu4CCZke3AzBp+a67OcEuT3dsz2YyZST9RCfSw7YY0l33YCo5SESnp8d0R+J/
# mNf6xnWkwUY0FRaqG/9auNc+rq2n0CeuP2fDgYcUDBlZAXf8kFAchzN4AuOKu7O8
# Sxt6prkoHY+ZysWdTqomcrOEnoLzh08bzgB0nQpg5I8VxurP67dLGPIKF+eEYEzC
# xNS98q/tIHj8FdDOIaO0/DKTZFiKtx6qJ1c0hFHfgYC5YinVUXExcYlNM8OHZR9t
# fpoEA9xPVhYnSCuHwygjWUUoN/IFbS4zw86aifj1kRPPXSOD7SDA+Jouck4OFsF+
# L8tfBuVZiTL+lRXviAgkHnuBPHGdckFNSomJDiuec4s0I46rdFj4yH6T9ZUWfOyo
# L2Vk/6CoJbod1mfA9mUjpbtRUcOBp4Pa9ip8pfZsCLmPTg3coHkm9tKHov9SlffO
# qH30YhLMwH9+j9kpY8ySVNBERwVKiQIDAQABo4ICAzCCAf8wHwYDVR0jBBgwFoAU
# aDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFH3+vkhYR5myjjPYsgJbajas
# 0CwrMD4GA1UdIAQ3MDUwMwYGZ4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMwgbUGA1UdHwSBrTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0
# MjAyMUNBMS5jcmwwU6BRoE+GTWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3Js
# MIGUBggrBgEFBQcBAQSBhzCBhDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMFwGCCsGAQUFBzAChlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIx
# Q0ExLmNydDAJBgNVHRMEAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQBMYukq+4Vp7UIJ
# XYiV5p60Fpc4vFVeYYeaJVflZZXo4tG/Wze+w6zkSxVx0YQG+Jra5KDfFpHBIhDk
# VGMoHZKjpWBd2AbKnlG1u2+H/I2G6EAvx+FVfb4SwU1mrC3RsBs+qVX2ZjipVMSt
# EQQxt20rcZ/xtHCm3mkq0EkBISNwtRlixaPsuZVpI5cPkVQaGChjeHTDydJwwhHr
# Cu0RVFektrz4panug/hkhdKPMClkVd4DNmoNdM+O/W8K/5kxZ9gvuJV6HzHDe0AD
# K8Cu/J6N26FdLQqF8n9lsWOQ5C+eVwhwY6E6QeqCsFpCoyuPz05Ri6iits1ZMqw4
# +VuUtSzq7Lg6OR0MoMKyxykHJiTGL+DfGHNzbKcBPCVoADBAgqCYwMfbSwu9Dis7
# MXRrMfENJdB/v9TBhV8TsO4g19MMEAz1bA11ELXSLak3KlUck8WFwcbT/ANzVjhW
# nrN4m1FYiavUW2LVJhvwQgbEWUo6bjx+CWbS1NbNS9cI7okUqnOFdfph1Dk7bIMU
# aLqE1lF8UtBNX1fwW8Ozz0pfCzZACPcdZgd+e9MOf/KKRej4wJBA9njRyqrPLp5I
# cN/FJYIGofnFlaLthgsBAHqI522tke5Mp4B6tNm0AccrLAUHpSaL/o/T7LoFdMoY
# 1vwO0dbkaREQlqvxCze2CUGHKPrnJDGCGiEwghodAgEBMH0waTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQ
# AY0ytORypiZifLlHB5AfVjANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwx
# AjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAoa1fmFCSwLB95bV0EP+R3Y4gE
# MDiIeEC/JskSrpurljANBgkqhkiG9w0BAQEFAASCAYC9Mjs5uLqlqxWM1rA1qSgR
# iZg3mbiaBJF5T9r7BmkiCdHicE+fqY39lkvwKznOye3wb5pdtpgsDqvmFtN6Zn3G
# +uqbMKcrblLqIrSB9EHTjVyrPp+mO4wDSXI5bS309yhI/h+FyKMVEXtRXHct8zxY
# pLxmWdCl9MBXD1DiK4CgoSzzh3esv8H2IpWe6aagO91xGaUE36yoxYd2qZi7/6RS
# idhJ8as+t9i+mo9Fi6eT2ls9SlcMNQ18xL0OS7PkcMhZYzpwYY1t7faQLzZI0RjH
# 1/C4sjtqRh1hAQhdEot19gyUEcnLadxhVeGhsQJbSf717pcfPjTHKbDOr8KmsJst
# 750X2w0JIGgpkrv79dKMmFk/eEa2UXn7paQY3Yzb31JwmAOaOqZqnHtXPshAM0Nv
# 1ykttMK2a1hLlUZBxhWO0IjdsJJmW6Mjxg7Kmq+JEtBedRLMYkdfKxpW/alCwhtQ
# EL3pgPTs1F3rskqgovqwhb3FJ1xinh3cJIizqn11JHChghd3MIIXcwYKKwYBBAGC
# NwMDATGCF2MwghdfBgkqhkiG9w0BBwKgghdQMIIXTAIBAzEPMA0GCWCGSAFlAwQC
# AQUAMHgGCyqGSIb3DQEJEAEEoGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgB
# ZQMEAgEFAAQguWbZJbGWXIwKV2qRdDp434vYbx/L8D+4b7rjkbmNG5cCEQDLV+dl
# 7hN7+ygSpqDKkbYYGA8yMDI2MDUwNzE5MzcxNlqgghM6MIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzCCBrQwggScoAMCAQIC
# EA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTI1MDUwNzAw
# MDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRp
# Z2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVT
# dGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBALR4MdMKmEFyvjxGwBysddujRmh0tFEXnU2tjQ2UtZmW
# gyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4aPCOo2N8S9SLrC6Kbltqn7SWCWgzb
# NfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dDGpeZGKe+42DFUF0mR/vtLa4+gKPs
# YfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM1iI5PHg62IVwxKSpO0XaF9DPfNBK
# S7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+SAWSuIr21Qomb+zzQWKhxKTVVgtmU
# PAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4aS4CEeIY8y9IaaGBpPNXKFifinT7z
# L2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKCgs+nrpuQNfVmUB5KlCX3ZA4x5HHK
# S+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPsFfxW1gaou30yZ46t4Y9F20HHfIY4
# /6vHespYMQmUiote8ladjS/nJ0+k6MvqzfpzPDOy5y6gqztiT96Fv/9bH7mQyogx
# G9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtTasySkuJDpsZGKdlsjg4u70EwgWbV
# RSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSpWM8o5a6D8bpfm4CLKczsG7ZrIGNT
# AgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTvb1NK
# 6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUH
# AQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYI
# KwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcw
# CAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAF877FoAc
# /gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tcBnPw6O6FTGNpoV2V4wzSUGvI9NAz
# aoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+ReOPK0mCefSG+tXqGpYZ3essBS3q
# 8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKEfJ+nN57mQfQXwcAEGCvRR2qKtntu
# jB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDRAXx1Neq9ydOal95CHfmTnM4I+ZI2
# rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzHU0pTi4dBwp9nEC8EAqoxW6q17r0z
# 0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiKNqetRHdqfMTCW/NmKLJ9M+MtucVG
# yOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNMsvhlqgF2puE6FndlENSmE+9JGYxO
# GLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0xJuF2EZAOk5eCkhSxZON3rGlHqhpB
# /8MluDezooIs8CVnrpHMiD2wL40mm53+/j7tFaxYKIqL0Q4ssd8xHZnIn/7GELH3
# IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8uw3PdBunvAZapsiI5YKdvlarEvf8
# EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1wwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQxggN8MIIDeAIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBU
# aW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHE
# dqeVdGgwDQYJYIZIAWUDBAIBBQCggdEwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJ
# EAEEMBwGCSqGSIb3DQEJBTEPFw0yNjA1MDcxOTM3MTZaMCsGCyqGSIb3DQEJEAIM
# MRwwGjAYMBYEFN1iMKyGCi0wa9o4sWh5UjAH+0F+MC8GCSqGSIb3DQEJBDEiBCDR
# kOmhSzre0S8IazPhHY8dILdwrRJudNVqxPURIrLSqTA3BgsqhkiG9w0BCRACLzEo
# MCYwJDAiBCBKoD+iLNdchMVck4+CjmdrnK7Ksz/jbSaaozTxRhEKMzANBgkqhkiG
# 9w0BAQEFAASCAgBUUapnYsxofAmBNuDmk0ZiA0O9R596W4vun/a55u/h+E7oVEpI
# GvOjTxNi0a9r+rAdcKvnbAP7M9f1UPjrOdgjg9824/cvzmxYL1u+j+mCDPEDkFDk
# 7S6JJDbq10yNh91ANAtSS48/EQ+2l+XEwinKSf79/Q8rrb9qrkvrpT5KPVu185fJ
# SqeLStvs+avdrpRtbB99g/Wgv5+KnrQ4HvyBG/0maRzQPZJ6A+Xld5OjGSAC2QzG
# gpL7bSkjm7cJJdv8tSe/NH29P2ITPCzL3+lnhXH624LvpEy+XVVjbELt6Z8CbnRg
# SkekMwBpH1w9pBqG1roHPWCUX6jvaDxWOwszgF9lr1Il+HkfoZygxGoqUK1GQiw0
# YSei9ziqLah1h/qKXRf9dgJtFSAgpQ/793OJ2kSRhka42HSqF7EomuMP75bmY5DH
# Gk1AsDXZQVpariFUx4nKwWHkJUUPc9KjbpQK1uomnU2imlei2J1duiRfau5lfL2M
# M8uzlNmGF3IMl7+LHLMe8wWaVYikwo6D6TZ90ldZLa9p5B1+yyS09QK4LdkQmm5n
# ywi8er/9mOnQGrBLwIg+EJB4/bT1zomKEKpwwi2gkICo1pBiNcTXdw3S7vXvrr4r
# SYOwvcFmNgEgBFRWVpOlqgksLeSGG9YYNdDjJAdTd2SByINPk/azFGZIOQ==
# SIG # End signature block

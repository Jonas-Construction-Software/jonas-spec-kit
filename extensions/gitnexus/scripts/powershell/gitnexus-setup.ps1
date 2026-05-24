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

# SIG # Begin signature block
# MIIodwYJKoZIhvcNAQcCoIIoaDCCKGQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZYw8efY5CkscR
# uZGOpMc2pletS/6i6DEiOzB8XaLJ+aCCDawwggawMIIEmKADAgECAhAIrUCyYNKc
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCC5Ic7MkKBDqfFd5hSNB9OUGTl/
# A6iZzQBq/+3XHpryDDANBgkqhkiG9w0BAQEFAASCAYATMTkXlDskqCuBVRyS6Tj5
# LmGzUoQjGNPQRsR51O9N6uU9T1e5j5JLwzzzTmUDzwtKjFSF3aunP4HhLb/fbAp4
# 6z90FXgq8BZ9bUgr+IRa5z2WoL7kN9xuHWnq5aEi2Ng2PqkvP4L7Ktp0cX2CIM3y
# 27sabFb2hJykGGLzjdf18GCFQHUa5ny0xxieyhW03Q6KotQ6t0pwXb7IXSBgxyYR
# 27kVA4id208riOVsb7aOefG2BEidC6Ygq63kQZ9uzfhKAybQQ2CUnGh5yqotWAkl
# Z1bD/ZmbBDQ7AXWxIUZi1Uhk/fFFmGl4+I8le9RqvSeH3UW52uim3blNl2neRcjG
# FY9FONFRq2E6lF1Aw5n583Ryy9kM2qW0zN9yOoidfRs1IhcAJ+Uvg30eYXs8BYSu
# DBZsQeB/yNmMImAty9b6UkZe3eY/s27c2Zd1RubmPfftfJg+5DjmOGfQMizStdX/
# bm7TytVdzrBHd1ZcImsSw7IRyzBkL24816U7FHDv/auhghd3MIIXcwYKKwYBBAGC
# NwMDATGCF2MwghdfBgkqhkiG9w0BBwKgghdQMIIXTAIBAzEPMA0GCWCGSAFlAwQC
# AQUAMHgGCyqGSIb3DQEJEAEEoGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgB
# ZQMEAgEFAAQgEVC4ofjp1jV0SIf+nJ2Ma2xrRLXV9o2cedeKO59b80UCEQC1epVo
# i91/Nj8zctJsxmgkGA8yMDI2MDUwNzE5MzY1M1qgghM6MIIG7TCCBNWgAwIBAgIQ
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
# EAEEMBwGCSqGSIb3DQEJBTEPFw0yNjA1MDcxOTM2NTNaMCsGCyqGSIb3DQEJEAIM
# MRwwGjAYMBYEFN1iMKyGCi0wa9o4sWh5UjAH+0F+MC8GCSqGSIb3DQEJBDEiBCD0
# CYtDzwrPqdckpYfaItgbsf2NisaCom3x3wr1v5ptjTA3BgsqhkiG9w0BCRACLzEo
# MCYwJDAiBCBKoD+iLNdchMVck4+CjmdrnK7Ksz/jbSaaozTxRhEKMzANBgkqhkiG
# 9w0BAQEFAASCAgBIEXYeDDuzGNlT2j6mHv1XTSYCTwHDTwthgZsQxzrfJ8vKeRE2
# i8qrkvA49PxtTzjYkeCFndZQvdxLBfRCS80G39P68rrFvp9duDRkxiNnygRTOUGA
# tVLa+L87YcTCQyObsKRniBU2ELagHpNtYoHMAg/u8nwAeXnGkatXFjuhdufsYw3V
# 8LAfyH1h9duMbJvas+3BXFKCCE9ssTeWa3G8U353Fg/NyN/lDDcWBKhlETTzCdMk
# 7S6H+r6EYRvgmZm4KOtx4uxsXmkq1g1H0mpVr7TGNvcF4DKcxG0KIHHSSOa/z5Q5
# zhBP9hjyhKjHszgbzzbePEe2ErgP8hed33cc1UeLis/iAlkiuJXTQax31sr+S2Ee
# zqc4jf4OotFUEJngMQTAj+AawLXCZmiqbeDHMAKGlxLEu0rRihPtxcEDr2HLBXNJ
# uw0xglh2nqhtg9Sn1kZneGLF/jBx4wTha7OLvcHlqHaIsHtY+5nRgulh6uRzISiF
# qokZ1eyesMqbrsDZTysOw2FhrakKljgif2bly7DeESpYzc4ZVtR8g7/yA5oK0n/A
# CF5IpBuD5hBtLZn3+Dgmr7Iv2YW18uK68DxhfTMtk0iMx865PGVv0SHkBB0i2Zkg
# ytxWzEGxeJKZQeDrLKmLiCe07y2qF3Mnb+fLqQIWKqVv8DpRDCjMgYgYBg==
# SIG # End signature block

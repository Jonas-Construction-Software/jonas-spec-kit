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

# SIG # Begin signature block
# MIIodQYJKoZIhvcNAQcCoIIoZjCCKGICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDEyicYAmWve9jc
# 4QyC5Nbq7yJx85LQCnOnXknWRkohWaCCDawwggawMIIEmKADAgECAhAIrUCyYNKc
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
# 1vwO0dbkaREQlqvxCze2CUGHKPrnJDGCGh8wghobAgEBMH0waTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQ
# AY0ytORypiZifLlHB5AfVjANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwx
# AjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDcP504fw/PirDwForCZRXUCbYL
# FzKqVxiZ0dInXJioUjANBgkqhkiG9w0BAQEFAASCAYDHg7+5Mc6Ep/uz4o/f1GDK
# M+tAV/6NOEM9cwcus4nT9BqZ9kgL7F1AoWzu1E507fx9JFBTYd38PFymk1a0U2gu
# 5mOIoJ4/GjLDlTzcTZxEcUv3tcla7cOuaeJyHcb6BjLr7bzEtsCzMTu7z6FpQFii
# PlRBCDwr6HeXK+yI0ayusAk0dP09IBtIOsR23VMY3j1XO7cgVV4akpCiu47ekywA
# 2EaFCHOhFvfVhSdDTsKtnlRMBtCjOyW292Fdjm+1QORuQW0X0UUKXuwS4bm1pMVv
# xHRtmV0YL0xxgHAfhYXaqFCgYD3DjRjs+Xw5z4plerV82eYMRqDZC0Q7uampu7JW
# ZbUBd33u/yHtoESgi+CVRwyQbPjHngCLKPZ8cGEs+9DaB4vnYp5CKimxEnUe3F2f
# kmoVUdH2IV7a/FOwytvnAQdb6hCIQN+rxjVA09dlHa0+2htH+hPqvDEEH+yQWTYH
# W8rayTyc18UcK1HYFtM75UM9AmVxEdhskctgv1DRwOuhghd1MIIXcQYKKwYBBAGC
# NwMDATGCF2EwghddBgkqhkiG9w0BBwKgghdOMIIXSgIBAzEPMA0GCWCGSAFlAwQC
# AQUAMHYGCyqGSIb3DQEJEAEEoGcEZTBjAgEBBglghkgBhv1sBwEwMTANBglghkgB
# ZQMEAgEFAAQgjksDWEFCKHgCHE+vrtHK/hIYwda1WIAuu8iseYPvLE0CDyyKUikv
# 1B0qcjbKi3WzmBgPMjAyNjA1MDcxOTM3MDZaoIITOjCCBu0wggTVoAMCAQICEAqA
# 7xhLjfEFgtHEdqeVdGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAV
# BgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVk
# IEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0yNTA2
# MDQwMDAwMDBaFw0zNjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJTQTQw
# OTYgVGltZXN0YW1wIFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBjMqiZ
# 3xTWcfsLwOvRxUwXcGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNkeECqV
# Q+3bzWYesFtkepErvUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4vEjo
# T1FpS54dNApZfKY61HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7VA1R
# 0V3Zp3DjjANwqAf4lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqgr6Un
# bksIcFJqLbkIXIPbcNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3NR39
# iTTFS+ENTqW8m6THuOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETkVWz0
# dVVZw7knh1WZXOLHgDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1p6ll
# N3QgshRta6Eq4B40h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uck5Wg
# gn8O2klETsJ7u8xEehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYRNMmS
# F3voIgMFtNGh86w3ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5pwID
# AQABo4IBlTCCAZEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X85Fx
# YxlQQ89hjOgwHwYDVR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYDVR0P
# AQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcBAQSB
# iDCBhTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0GCCsG
# AQUFBzAChlFodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYDVR0f
# BFgwVjBUoFKgUIZOaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAGA1Ud
# IAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEA
# ZSqt8RwnBLmuYEHs0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavXzWjZ
# hY+hIfP2JkQ38U+wtJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4pvP/
# ciZmUnthfAEP1HShTrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluHWiKk
# 6FxRPyUPxAAYH2Vy1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WDl/FQ
# USntbjZ80FU3i54tpx5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaaslNXdC
# G1+lqvP4FbrQ6IwSBXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCEH1Y5
# 8678IgmfORBPC1JKkYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXSd+V0
# 8X1JUPvB4ILfJdmL+66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUtwq1q
# mcwbdUfcSYCn+OwncVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5SlfY
# xJ7La54i71McVWRP66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn5PhD
# Bf3Froguzzhk++ami+r3Qrx5bIbY3TVzgiFI7Gq3zWcwgga0MIIEnKADAgECAhAN
# x6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# ITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcwMDAw
# MDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdp
# Q2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3Rh
# bXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51NrY0NlLWZloMs
# VO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5bap+0lgloM2zX4
# kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf77S2uPoCj7GH8
# BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQSku2
# Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80FiocSk1VYLZlDwF
# t+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+8y9o
# HRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl92QOMeRxykvq
# 6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGPRdtBx3yGOP+r
# x3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//Wx+5kMqIMRvU
# BDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm1UUl
# 9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM7Bu2ayBjUwID
# AQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU729TSunk
# Bnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08w
# DgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEB
# BGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsG
# AQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgG
# BmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBABfO+xaAHP4H
# PRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQM2qE
# JPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt6vJy
# 9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr0UdqirZ7bowe
# 9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmSNq1U
# H410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKqMVuqte69M9J6
# A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiyfTPjLbnFRsjs
# Yg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmMThi0
# vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTjd6xpR6oaQf/D
# Jbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx9yHb
# xtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3/BAP
# vIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv
# 21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQD
# ExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcN
# MzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2Vy
# dCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf
# 8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1
# mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe
# 7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecx
# y9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX
# 2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX
# 9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp49
# 3ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCq
# sWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFH
# dL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauG
# i0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYw
# DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08w
# HwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGG
# MHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXn
# OF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23
# OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFI
# tJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7s
# pNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgi
# wbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cB
# qZ9Xql4o4rmUMYIDfDCCA3gCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMO
# RGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGlt
# ZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8YS43xBYLRxHan
# lXRoMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRAB
# BDAcBgkqhkiG9w0BCQUxDxcNMjYwNTA3MTkzNzA2WjArBgsqhkiG9w0BCRACDDEc
# MBowGDAWBBTdYjCshgotMGvaOLFoeVIwB/tBfjAvBgkqhkiG9w0BCQQxIgQgwyQM
# bgUPV4DG976zD0tvvkB5NHmm/HtUCSgGot5wVRUwNwYLKoZIhvcNAQkQAi8xKDAm
# MCQwIgQgSqA/oizXXITFXJOPgo5na5yuyrM/420mmqM08UYRCjMwDQYJKoZIhvcN
# AQEBBQAEggIAHwqBl6k5Fg6reFGb72dcNQZGsLR6IGTJWsL1XIH7TYTF6fIqSVru
# mKldypYf3yWMna0aD003ZAveGyVUZF1quh4M0LIsFHkkkNmcAFTHgO7ztzaFI1R5
# 0fyO02bF05eH1JkS5jyWCQ4SkpNchjbYVDZe1YvTF2/FPeS34j6KAgiBTuHs0OWG
# PwGjvmo+elmmRo19ibd7upw3GFepSdGZ6g5q1YihF93GGJjUNSjxcYo3nYvmNMPw
# D98DDRwwqVNw7FziJpyoKLXpX3cGjuiSvodigooM4Y4DoyvsihcxpFAninfNezaK
# IYhgAfLS87t192Yi0H02BB+E9WZdtEuzPzgnAzQs4JhXIq5k8K4MGJBmT/ksiVS9
# tYFi1QX1e767XBrGNCWRn2lhkSFS64c7IQ2WB4Rqeje77dFD9wFWBLsBXs3vZRtT
# e2l71Nk1FipD/NA0qnL6LR10Vu9IbF4akOaZfKYAuMz1MEU504RRfSqCWpLXffGG
# 671zfCIqSfWwqgLmAdOQGYurJdjuT/gM5Ox+HJGXBlxSz+02q6jZT8whZ7SUNZa5
# vY4kGbS3bF3bUqTWVVJYw4kn+/uiZn1ZkfWzL3+ji4EbqdtjfldOJkecLg4MDKTs
# EBPxEDayxvqob8jcIs/SiPmzzb7IqIuo4atnU73mwDXg+cqyl3Rglic=
# SIG # End signature block

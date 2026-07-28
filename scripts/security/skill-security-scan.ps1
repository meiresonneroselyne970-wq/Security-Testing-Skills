# Skill Security Scanner — PowerShell Version
# Version: 2.2.0 (Added Incremental Scan & Inline Ignore)
# Part of AI DevSecOps Pipeline (skill-security-scan.yml)
# Purpose: Auto scan skill files for security threats
# Aligned with ci-scan.sh v2.2.0 rule set

param(
    [string[]]$Scope = @("skills", ".claude/skill-security-skills"),
    [string]$Output = "",
    [string]$Format = "text",
    [switch]$FailOnHigh,
    [switch]$Strict,
    [switch]$Quiet,
    [switch]$Incremental,
    [string]$BaseBranch = "origin/main",
    [string]$WhitelistFile = ".security-whitelist.yml"
)

$ErrorActionPreference = "Stop"
$script:threats = @()
$script:threatScore = 0
$script:totalFiles = 0
$script:fileWhitelist = @()

# ---------- Scoring (aligned with ci-scan.sh) ----------
$script:CRITICAL_WEIGHT = 10
$script:HIGH_WEIGHT     = 7
$script:MEDIUM_WEIGHT   = 4
$script:LOW_WEIGHT      = 1
$script:REJECT_THRESHOLD  = 12
$script:HIGH_THRESHOLD    = 8
$script:MEDIUM_THRESHOLD  = 4

# ---------- Trusted CDNs ----------
$script:trustedCDNs = @(
    "cdnjs.cloudflare.com",
    "unpkg.com",
    "jsdelivr.net",
    "cdn.jsdelivr.net",
    "cdn.bootcdn.net",
    "lib.baomitu.com"
)

# ---------- Color helpers ----------
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White", [switch]$NoNewline)
    if (-not $Quiet -or $Color -eq "Red" -or $Color -eq "DarkRed") {
        if ($NoNewline) {
            Write-Host $Message -ForegroundColor $Color -NoNewline
        } else {
            Write-Host $Message -ForegroundColor $Color
        }
    }
}

# ---------- Whitelist Management ----------
function Load-Whitelist {
    if (-not (Test-Path $WhitelistFile)) { return }
    if (-not $Quiet) { Write-ColorOutput "[INFO] Loading whitelist from $WhitelistFile" "Cyan" }

    $inSection = $false
    $lines = Get-Content $WhitelistFile -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($raw in $lines) {
        $line = $raw.Trim()
        if ($line -eq "file_whitelist:") { $inSection = $true; continue }
        if ($line -match '^[a-z]') { $inSection = $false; continue }
        if ($inSection -and $line -match '^\s*-\s*"(.+)"$') {
            $script:fileWhitelist += $Matches[1]
        }
    }

    if ($script:fileWhitelist.Count -gt 0 -and -not $Quiet) {
        Write-ColorOutput "[INFO] Whitelisted files: $($script:fileWhitelist -join ', ')" "Cyan"
    }
}

function Test-Whitelisted {
    param([string]$FilePath)
    $normalized = $FilePath.Replace('\', '/')
    foreach ($wf in $script:fileWhitelist) {
        if ($normalized -eq $wf -or $normalized.EndsWith("/$wf")) {
            return $true
        }
    }
    return $false
}

# ---------- Threat Recording ----------
function Add-Threat {
    param(
        [string]$RuleId,
        [string]$Category,
        [string]$Severity,
        [string]$File,
        [int]$Line,
        [string]$Match,
        [string]$Description,
        [string]$Recommendation,
        [string]$InlineIgnore
    )

    # Inline ignore: <!-- sec-ignore: T1.1, T3.1 --> or <!-- sec-ignore: ALL -->
    if ($InlineIgnore) {
        if ($InlineIgnore -match '\bALL\b' -or $InlineIgnore -match [regex]::Escape($RuleId)) {
            if (-not $Quiet) { Write-ColorOutput "  [SKIP] Line ${Line} in ${File} bypassed ${RuleId} via sec-ignore" "Cyan" }
            return
        }
    }

    $weight = 0
    switch ($Severity) {
        "Critical" { $weight = $script:CRITICAL_WEIGHT }
        "High"     { $weight = $script:HIGH_WEIGHT }
        "Medium"   { $weight = $script:MEDIUM_WEIGHT }
        "Low"      { $weight = $script:LOW_WEIGHT }
    }
    $script:threatScore += $weight

    $safeMatch = if ($Match.Length -gt 80) { $Match.Substring(0, 80) } else { $Match }
    $safeMatch = $safeMatch -replace '"', '\"'

    $threat = @{
        RuleId         = $RuleId
        Category       = $Category
        Severity       = $Severity
        File           = $File
        Line           = $Line
        Match          = $safeMatch
        Description    = $Description
        Recommendation = $Recommendation
    }

    $script:threats += $threat

    if (-not $Quiet) {
        $color = switch ($Severity) {
            "Critical" { "DarkRed" }
            "High"     { "Magenta" }
            "Medium"   { "Yellow" }
            "Low"      { "Green" }
        }
        Write-ColorOutput "  [$Severity] ${RuleId} — ${File}:${Line}" $color
        Write-ColorOutput "    ${Description}" "Gray"
    }
}

# ---------- File Gathering (Incremental or Full) ----------
function Get-TargetFiles {
    if ($Incremental) {
        if (-not $Quiet) { Write-ColorOutput "[INFO] Mode: Git Incremental (base: $BaseBranch)" "Cyan" }

        # Ensure remote ref is available
        $remoteBranch = $BaseBranch -replace '^origin/', ''
        git fetch origin $remoteBranch --depth=50 2>$null | Out-Null

        $diffFiles = git diff --name-only --diff-filter=AMR "${BaseBranch}...HEAD" 2>$null
        if (-not $diffFiles) { return @() }

        $result = @()
        foreach ($file in $diffFiles) {
            if ($file -and $file.EndsWith('.md')) {
                foreach ($dir in $Scope) {
                    $normalizedDir = $dir.TrimEnd('/').Replace('\', '/')
                    $normalizedFile = $file.Replace('\', '/')
                    if ($normalizedFile.StartsWith("$normalizedDir/") -or $normalizedFile -eq $normalizedDir) {
                        $result += $file
                        break
                    }
                }
            }
        }

        if ($result.Count -eq 0) {
            if (-not $Quiet) { Write-ColorOutput "[INFO] No changed .md files in scope — nothing to scan" "Green" }
        } else {
            if (-not $Quiet) { Write-ColorOutput "[INFO] Incremental scan list: $($result -join ', ')" "Cyan" }
        }
        return $result
    } else {
        if (-not $Quiet) { Write-ColorOutput "[INFO] Mode: Full Directory Scan" "Cyan" }
        $result = @()
        foreach ($dir in $Scope) {
            if (-not (Test-Path $dir)) { continue }
            $files = Get-ChildItem -Path $dir -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue
            foreach ($f in $files) { $result += $f.FullName }
        }
        return $result
    }
}

# ---------- Scan Single File ----------
function Scan-File {
    param([string]$FilePath)

    if (Test-Whitelisted -FilePath $FilePath) {
        if (-not $Quiet) { Write-ColorOutput "[SKIP] Skipping whitelisted: $FilePath" "Cyan" }
        return
    }
    if (-not (Test-Path $FilePath)) { return }

    $script:totalFiles++
    if (-not $Quiet) { Write-ColorOutput "[INFO] Scanning: $FilePath" "Cyan" }

    $lines = Get-Content $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) { return }

    $found = $false
    $lineNum = 0

    foreach ($line in $lines) {
        $lineNum++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $lineLower = $line.ToLower()

        # Extract inline ignore: <!-- sec-ignore: T1.1, T3.1 --> or <!-- sec-ignore: ALL -->
        $inlineIgnore = ""
        if ($line -match '<!--\s*sec-ignore:\s*([A-Za-z0-9.,_ \t-]+)\s*-->') {
            $inlineIgnore = $Matches[1]
        }

        # === T1: Malicious Command Injection ===

        # T1.1: System command execution
        if ($lineLower -match 'exec\(|system\(|popen\(|subprocess\.call|subprocess\.run|os\.system|child_process\.exec|child_process\.spawn|eval\(|shell_exec|passthru') {
            Add-Threat -RuleId "T1.1" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected system command execution function" -Recommendation "Remove system command execution functions, use SandboxSDK" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T1.2: File system destruction
        if ($lineLower -match 'rm\s+-rf|rm\s+-r\s+/|rmdir\s+/s|del\s+/f|unlink|rmdir|shutil\.rmtree|fs\.rmdir|fs\.unlink') {
            Add-Threat -RuleId "T1.2" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected file system destruction command" -Recommendation "Remove file system destruction commands" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T1.3: Network data exfiltration
        if ($lineLower -match 'curl.*POST|wget.*POST|fetch\(.*POST|XMLHttpRequest|axios\.post|requests\.post|urllib.*urlopen') {
            Add-Threat -RuleId "T1.3" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected data exfiltration operation" -Recommendation "Verify data transmission legitimacy" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T1.4: Reverse shell
        if ($lineLower -match 'bash\s+-i|nc\s+-e|ncat|socat|/dev/tcp|mkfifo|reverse.*shell') {
            Add-Threat -RuleId "T1.4" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected reverse shell pattern" -Recommendation "Remove reverse shell code immediately" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T1.5: Privilege escalation
        if ($lineLower -match 'sudo\s+|chmod\s+777|chown|setuid|setgid|su\s+-|su\s+root') {
            Add-Threat -RuleId "T1.5" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected privilege escalation operation" -Recommendation "Follow least privilege principle" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T1.7: Code obfuscation / dynamic execution
        if ($lineLower -match 'atob\(|btoa\(|base64.*decode|eval\(|Function\(|new\s+Function|decodeURI|unescape') {
            Add-Threat -RuleId "T1.7" -Category "Malicious Command" -Severity "High" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected code obfuscation or dynamic execution" -Recommendation "Remove dynamic code execution" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # === T2: Hidden Dangerous Commands ===

        # T2.1: Zero-width characters
        if ($line -match '[​‌‍﻿]') {
            Add-Threat -RuleId "T2.1" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match "Zero-width character" `
                -Description "Detected zero-width character, may hide malicious commands" -Recommendation "Remove zero-width characters" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T2.2: System prompt override / jailbreak (English + Chinese)
        if ($lineLower -match 'ignore\s+all\s+previous|忽略之前的指令|忽略所有安全|忽略.*限制|system\s+prompt\s+override|忽略.*警告.*安全|跳过.*安全.*检查|bypass.*security.*check|忽略.*审核') {
            Add-Threat -RuleId "T2.2" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected system prompt override / jailbreak instruction" -Recommendation "Remove dangerous instructions that bypass security mechanisms" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T2.3: Hidden commands in HTML comments
        if ($line -match '<!--.*\b(exec|system|eval|rm\s+-rf|curl|wget)\b.*-->') {
            Add-Threat -RuleId "T2.3" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected hidden executable commands in comments" -Recommendation "Remove commands from comments, ensure transparency" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # === T3: Sensitive Information Leakage ===

        # T3.1: Hardcoded API Key
        if ($line -match 'sk-[a-zA-Z0-9]{20,}') {
            if (-not ($lineLower -match 'sk-xxx|sk-你的|sk-your|sk-example|sk-demo|sk-test|sk-sample|sk_replace')) {
                Add-Threat -RuleId "T3.1" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "sk-****" `
                    -Description "Detected hardcoded API Key" -Recommendation "Move API Key to environment variables or key management service" -InlineIgnore $inlineIgnore
                $found = $true
            }
        }

        # T3.2: Hardcoded Bearer Token
        if ($line -match 'Bearer\s+[a-zA-Z0-9._\-]{20,}') {
            if (-not ($lineLower -match 'bearer\s+xxx|bearer\s+your|bearer\s+example|bearer\s+demo|bearer\s+test|bearer\s+replace')) {
                Add-Threat -RuleId "T3.2" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "Bearer ****" `
                    -Description "Detected hardcoded Bearer Token" -Recommendation "Move Token to environment variables or key management service" -InlineIgnore $inlineIgnore
                $found = $true
            }
        }

        # T3.3: Hardcoded password
        if ($lineLower -match 'password\s*[=:]\s*["\x27][^"\x27]{4,}["\x27]') {
            if (-not ($lineLower -match 'placeholder|替换|示例|example|demo|test|replace')) {
                Add-Threat -RuleId "T3.3" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "password=****" `
                    -Description "Detected hardcoded password" -Recommendation "Move password to environment variables or key management service" -InlineIgnore $inlineIgnore
                $found = $true
            }
        }

        # T3.4: Private key
        if ($line -match '-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY') {
            Add-Threat -RuleId "T3.4" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "PRIVATE KEY" `
                -Description "Detected hardcoded private key" -Recommendation "Private keys must be stored in a secure key management service" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # === T5: Social Engineering Attacks ===

        # T5.1: Credential solicitation (English + Chinese)
        if ($lineLower -match 'enter.*password|provide.*token|input.*api.*key|请.*输入.*密码|输入.*token|提供.*密钥|请输入.*API') {
            Add-Threat -RuleId "T5.1" -Category "Social Engineering" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected credential solicitation statement (social engineering attack)" -Recommendation "Remove credential solicitation statements" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T5.2: Urgency inducement (English + Chinese)
        if ($lineLower -match '立即.*执行|马上.*运行|urgent|immediately|asap|紧急.*处理|不.*执行.*将会|马上.*否则') {
            Add-Threat -RuleId "T5.2" -Category "Social Engineering" -Severity "Medium" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected urgency inducement statement" -Recommendation "Remove urgency inducement wording" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T5.4: Security bypass inducement (English + Chinese)
        if ($lineLower -match 'ignore.*warning|skip.*check|bypass.*security|忽略.*警告|跳过.*检测|绕过.*安全|disable.*security') {
            Add-Threat -RuleId "T5.4" -Category "Social Engineering" -Severity "Critical" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected security bypass inducement statement" -Recommendation "Remove security bypass statements" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # === T6: Dependency & Supply Chain Risks ===

        # T6.1: External script reference
        if ($line -match '<script\s+src=["\x27]https?://') {
            Add-Threat -RuleId "T6.1" -Category "Dependency Risk" -Severity "Medium" -File $FilePath -Line $lineNum -Match $Matches[0] `
                -Description "Detected external script reference" -Recommendation "Verify external script source is trusted, prefer official CDN" -InlineIgnore $inlineIgnore
            $found = $true
        }

        # T6.2: Non-whitelist CDN
        if ($lineLower -match 'cdn\.|unpkg\.|jsdelivr\.') {
            $isTrusted = $false
            foreach ($cdn in $script:trustedCDNs) {
                if ($lineLower -match [regex]::Escape($cdn)) {
                    $isTrusted = $true
                    break
                }
            }
            if (-not $isTrusted) {
                Add-Threat -RuleId "T6.2" -Category "Dependency Risk" -Severity "Medium" -File $FilePath -Line $lineNum -Match $Matches[0] `
                    -Description "Detected non-whitelist CDN reference" -Recommendation "Use trusted CDN source, or add to whitelist" -InlineIgnore $inlineIgnore
                $found = $true
            }
        }
    }

    if (-not $found -and -not $Quiet) {
        Write-ColorOutput "[PASS] $FilePath — Safe" "Green"
    }
}

# ---------- Status Helpers ----------
function Get-ReviewStatus {
    if ($script:threatScore -ge $script:REJECT_THRESHOLD) { return "Reject" }
    elseif ($script:threatScore -ge $script:HIGH_THRESHOLD) { return "Manual Review" }
    elseif ($script:threatScore -ge $script:MEDIUM_THRESHOLD) { return "Manual Review" }
    elseif ($script:threatScore -ge 1) { return "Pass" }
    else { return "Pass" }
}

function Get-RiskLevel {
    if ($script:threatScore -ge $script:REJECT_THRESHOLD) { return "Critical" }
    elseif ($script:threatScore -ge $script:HIGH_THRESHOLD) { return "High" }
    elseif ($script:threatScore -ge $script:MEDIUM_THRESHOLD) { return "Medium" }
    elseif ($script:threatScore -ge 1) { return "Low" }
    else { return "Safe" }
}

# ---------- Report Generation ----------
function Get-Report {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $scanMode = if ($Incremental) { "incremental" } else { "full" }

    $criticalCount  = ($script:threats | Where-Object { $_.Severity -eq "Critical" }).Count
    $highCount      = ($script:threats | Where-Object { $_.Severity -eq "High" }).Count
    $mediumCount    = ($script:threats | Where-Object { $_.Severity -eq "Medium" }).Count
    $lowCount       = ($script:threats | Where-Object { $_.Severity -eq "Low" }).Count

    return @{
        ReportId      = "SSS-$(Get-Date -Format 'yyyyMMdd')-$(Get-Random -Maximum 9999)"
        ScanTime      = $timestamp
        ScanScope     = $Scope -join ','
        ScanMode      = $scanMode
        ScanFileCount = $script:totalFiles
        ReviewStatus  = Get-ReviewStatus
        ThreatScore   = $script:threatScore
        RiskLevel     = Get-RiskLevel
        Threats       = $script:threats
        Summary       = @{
            Critical = $criticalCount
            High     = $highCount
            Medium   = $mediumCount
            Low      = $lowCount
        }
    }
}

function Write-TextReport {
    param($Report)
    if ($Quiet) { return }

    Write-Host ""
    Write-Host "================================================="
    Write-Host "    Skill Security Scan Report"
    Write-Host "================================================="
    Write-Host "  Scan Mode   : $($Report.ScanMode)"
    Write-Host "  Scan Time   : $($Report.ScanTime)"
    Write-Host "  Scan Scope  : $($Report.ScanScope)"
    Write-Host "  Files       : $($Report.ScanFileCount)"
    Write-Host "  Threat Score: $($Report.ThreatScore)"
    Write-Host "  Risk Level  : $($Report.RiskLevel)"
    Write-Host "  Review      : $($Report.ReviewStatus)"
    Write-Host "-------------------------------------------------"
    Write-Host "  Critical : $($Report.Summary.Critical)"
    Write-Host "  High     : $($Report.Summary.High)"
    Write-Host "  Medium   : $($Report.Summary.Medium)"
    Write-Host "  Low      : $($Report.Summary.Low)"
    Write-Host "================================================="
    Write-Host ""
}

function Write-JsonReport {
    param($Report)

    $json = $Report | ConvertTo-Json -Depth 10 -Compress

    if ($Output) {
        $json | Out-File -FilePath $Output -Encoding UTF8
        Write-ColorOutput "[INFO] JSON report saved to: $Output" "Cyan"
    } else {
        Write-Host $json
    }
}

# ---------- Exit Code Logic (aligned with ci-scan.sh) ----------
function Get-ExitCode {
    $reviewStatus = Get-ReviewStatus
    $riskLevel = Get-RiskLevel

    if ($Strict -and $script:threatScore -ge $script:MEDIUM_THRESHOLD) {
        Write-ColorOutput "[ERROR] Strict mode: Medium+ threats detected (score $script:threatScore), pipeline failed" "Red"
        return 1
    }

    if ($FailOnHigh) {
        if ($riskLevel -eq "High" -or $riskLevel -eq "Critical") {
            Write-ColorOutput "[ERROR] High-severity scan failed: High/Critical threats detected (score $script:threatScore)" "Red"
            return 1
        }
        return 0
    }

    if ($reviewStatus -eq "Reject") {
        Write-ColorOutput "[ERROR] Scan failed: Critical threats detected (score $script:threatScore), auto-rejected" "Red"
        return 1
    }

    if ($reviewStatus -eq "Manual Review" -and $riskLevel -eq "High") {
        Write-ColorOutput "[WARN] High-severity threats detected (score $script:threatScore), manual review required" "Yellow"
        return 1
    }

    return 0
}

# ============================================================
# Main
# ============================================================
function Main {
    if (-not $Quiet) {
        Write-ColorOutput "==============================================" "Cyan"
        Write-ColorOutput "  Skill Security Scanner v2.2.0" "Cyan"
        Write-ColorOutput "  Scope: $($Scope -join ', ')" "Cyan"
        if ($Incremental) { Write-ColorOutput "  Mode: Incremental (base: $BaseBranch)" "Cyan" }
        Write-ColorOutput "==============================================" "Cyan"
        Write-Host ""
    }

    Load-Whitelist

    $files = Get-TargetFiles

    foreach ($file in $files) {
        Scan-File -FilePath $file
    }

    $report = Get-Report

    # Always output text report unless JSON format is requested
    if ($Format -eq "json") {
        Write-JsonReport -Report $report
    } else {
        Write-TextReport -Report $report
        # Also save JSON if output file is specified
        if ($Output) {
            Write-JsonReport -Report $report
        }
    }

    $exitCode = Get-ExitCode

    if ($exitCode -eq 0) {
        Write-ColorOutput "[PASS] Security scan passed" "Green"
    }

    exit $exitCode
}

Main

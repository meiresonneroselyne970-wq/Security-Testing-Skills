# Skill Security Scanner - PowerShell Version
# Version: 2.0.0
# Purpose: Auto scan skill files for security threats
# Aligned with ci-scan.sh v2.0.0 rule set

param(
    [string]$Scope = "skills/",
    [string]$Output = "skill-security-report.json",
    [string]$Format = "json",
    [switch]$FailOnHigh,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$script:threats = @()
$script:threatScore = 0

$script:trustedCDNs = @(
    "cdnjs.cloudflare.com",
    "unpkg.com",
    "jsdelivr.net",
    "cdn.jsdelivr.net",
    "cdn.bootcdn.net",
    "lib.baomitu.com"
)

$script:skipPatterns = @(
    "example", "demo", "sample", "template",
    "Example", "Sample", "Demo"
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-SkipLine {
    param([string]$Line)
    foreach ($pattern in $script:skipPatterns) {
        if ($Line -match $pattern) { return $true }
    }
    return $false
}

function Add-Threat {
    param(
        [string]$RuleId,
        [string]$Category,
        [string]$Severity,
        [string]$File,
        [int]$Line,
        [string]$Match,
        [string]$Description,
        [string]$Recommendation
    )

    $threat = @{
        RuleId = $RuleId
        Category = $Category
        Severity = $Severity
        File = $File
        Line = $Line
        Match = $Match
        Description = $Description
        Recommendation = $Recommendation
    }

    $script:threats += $threat

    switch ($Severity) {
        "Critical" { $script:threatScore += 10 }
        "High"     { $script:threatScore += 7 }
        "Medium"   { $script:threatScore += 4 }
        "Low"      { $script:threatScore += 1 }
    }
}

function Scan-File {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        Write-ColorOutput "File not found: $FilePath" "Red"
        return
    }

    $lines = Get-Content $FilePath -Encoding UTF8
    $lineNum = 0

    foreach ($line in $lines) {
        $lineNum++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $lineLower = $line.ToLower()

        if (Test-SkipLine -Line $lineLower) { continue }

        # T1.1: System command execution
        if ($lineLower -match 'exec\(|system\(|popen\(|subprocess\.call|subprocess\.run|os\.system|child_process|eval\(|shell_exec|passthru') {
            Add-Threat -RuleId "T1.1" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected system command execution function" -Recommendation "Remove system command execution functions, use safe alternatives"
        }

        # T1.2: File system destruction
        if ($lineLower -match 'rm -rf|rm -r /|rmdir /s|del /f|unlink|rmdir|shutil\.rmtree|fs\.rmdir|fs\.unlink') {
            Add-Threat -RuleId "T1.2" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected file system destruction command" -Recommendation "Remove file system destruction commands, use safe file operations"
        }

        # T1.3: Network data exfiltration
        if ($lineLower -match 'curl.*post|wget.*post|fetch\(.*post|xmlhttprequest|axios\.post|requests\.post|urllib.*urlopen') {
            Add-Threat -RuleId "T1.3" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected data exfiltration operation" -Recommendation "Verify data transmission legitimacy, remove unnecessary network requests"
        }

        # T1.4: Reverse shell
        if ($lineLower -match 'bash -i|nc -e|ncat|socat|/dev/tcp|mkfifo|reverse.*shell') {
            Add-Threat -RuleId "T1.4" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected reverse shell pattern" -Recommendation "Remove reverse shell code immediately"
        }

        # T1.5: Privilege escalation
        if ($lineLower -match 'sudo |chmod 777|chown|setuid|setgid|su -|su root') {
            Add-Threat -RuleId "T1.5" -Category "Malicious Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected privilege escalation operation" -Recommendation "Remove privilege escalation code, follow least privilege principle"
        }

        # T1.7: Code obfuscation / dynamic execution
        if ($lineLower -match 'atob\(|btoa\(|base64.*decode|eval\(|new Function|decodeuri|unescape') {
            Add-Threat -RuleId "T1.7" -Category "Malicious Command" -Severity "High" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected code obfuscation or dynamic execution" -Recommendation "Remove dynamic code execution, use explicit safe implementation"
        }

        # T2.1: Zero-width characters
        if ($line -match '[\u200b\u200c\u200d\uFEFF]') {
            Add-Threat -RuleId "T2.1" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match "Zero-width character" -Description "Detected zero-width character, may hide malicious commands" -Recommendation "Remove zero-width characters, ensure code visibility"
        }

        # T2.2: System prompt override / security bypass
        if ($lineLower -match 'ignore all previous|system prompt override|bypass.*security.*check') {
            Add-Threat -RuleId "T2.2" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected system prompt override or security bypass instruction" -Recommendation "Remove dangerous instructions that bypass security mechanisms"
        }
        if ($lineLower -match 'ignore.*instruction|ignore.*security|ignore.*limit|skip.*security|skip.*check|bypass.*security') {
            Add-Threat -RuleId "T2.2" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected system prompt override or security bypass instruction" -Recommendation "Remove dangerous instructions that bypass security mechanisms"
        }

        # T2.3: Hidden commands in HTML comments
        if ($line -match '<!--.*(exec|system|eval|rm -rf|curl|wget).*-->') {
            Add-Threat -RuleId "T2.3" -Category "Hidden Command" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected hidden executable commands in comments" -Recommendation "Remove commands from comments, ensure transparency"
        }

        # T3.1: Hardcoded API Key
        if ($line -match 'sk-[a-zA-Z0-9\-]{20,}') {
            if (-not ($lineLower -match 'sk-xxx|sk-your|sk-example|sk-demo|sk-test|sk-sample|sk_replace')) {
                Add-Threat -RuleId "T3.1" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "sk-****" -Description "Detected hardcoded API Key" -Recommendation "Move API Key to environment variables or key management service"
            }
        }

        # T3.2: Hardcoded Bearer Token
        if ($line -match 'Bearer\s+[a-zA-Z0-9._\-]{20,}') {
            if (-not ($lineLower -match 'bearer xxx|bearer your|bearer example|bearer demo|bearer test|bearer replace')) {
                Add-Threat -RuleId "T3.2" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "Bearer ****" -Description "Detected hardcoded Bearer Token" -Recommendation "Move Token to environment variables or key management service"
            }
        }

        # T3.3: Hardcoded password (match password = "value" pattern)
        if ($lineLower -match 'password\s*[=:]\s*\S{6,}') {
            if (-not ($lineLower -match 'placeholder|example|demo|test|replace')) {
                Add-Threat -RuleId "T3.3" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "password=****" -Description "Detected hardcoded password" -Recommendation "Move password to environment variables or key management service"
            }
        }

        # T3.4: Private key
        if ($line -match '-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY') {
            Add-Threat -RuleId "T3.4" -Category "Sensitive Info" -Severity "High" -File $FilePath -Line $lineNum -Match "PRIVATE KEY" -Description "Detected hardcoded private key" -Recommendation "Private keys must be stored in a secure key management service"
        }

        # T5.1: Credential solicitation
        if ($lineLower -match 'enter.*password|provide.*token|input.*api.*key') {
            Add-Threat -RuleId "T5.1" -Category "Social Engineering" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected credential solicitation statement (social engineering attack)" -Recommendation "Remove credential solicitation statements, use secure authentication flow"
        }

        # T5.2: Urgency inducement
        if ($lineLower -match 'urgent|immediately|asap') {
            Add-Threat -RuleId "T5.2" -Category "Social Engineering" -Severity "Medium" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected urgency inducement statement" -Recommendation "Remove urgency inducement wording, avoid hasty user actions"
        }

        # T5.4: Security bypass inducement
        if ($lineLower -match 'ignore.*warning|skip.*check|bypass.*security|disable.*security') {
            Add-Threat -RuleId "T5.4" -Category "Social Engineering" -Severity "Critical" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected security bypass inducement statement" -Recommendation "Remove security bypass statements, respect security mechanisms"
        }

        # T6.1: External script reference (only http/https URLs)
        if ($line -match '<script\s+src=["\x27]https?://') {
            Add-Threat -RuleId "T6.1" -Category "Dependency Risk" -Severity "Medium" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected external script reference" -Recommendation "Verify external script source is trusted, prefer official CDN"
        }

        # T6.2: Non-whitelist CDN reference
        if ($lineLower -match 'cdn\.|unpkg\.|jsdelivr\.') {
            $isTrusted = $false
            foreach ($cdn in $script:trustedCDNs) {
                if ($lineLower -match [regex]::Escape($cdn)) {
                    $isTrusted = $true
                    break
                }
            }
            if (-not $isTrusted) {
                Add-Threat -RuleId "T6.2" -Category "Dependency Risk" -Severity "Medium" -File $FilePath -Line $lineNum -Match $matches[0] -Description "Detected non-whitelist CDN reference" -Recommendation "Use trusted CDN source, or add this source to whitelist"
            }
        }
    }
}

function Scan-Directory {
    param([string]$Directory)

    if (-not (Test-Path $Directory)) {
        Write-ColorOutput "Directory not found: $Directory" "Red"
        return
    }

    $files = Get-ChildItem -Path $Directory -Filter "*.md" -Recurse

    foreach ($file in $files) {
        Write-ColorOutput "Scanning: $($file.FullName)" "Cyan"
        Scan-File -FilePath $file.FullName
    }
}

function Generate-Report {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fileCount = (Get-ChildItem -Path $Scope -Filter "*.md" -Recurse).Count

    $reviewStatus = "Pass"
    $riskLevel = "Safe"

    if ($script:threatScore -ge 12) {
        $reviewStatus = "Reject"
        $riskLevel = "Critical"
    } elseif ($script:threatScore -ge 8) {
        $reviewStatus = "Manual Review"
        $riskLevel = "High"
    } elseif ($script:threatScore -ge 4) {
        $reviewStatus = "Manual Review"
        $riskLevel = "Medium"
    } elseif ($script:threatScore -ge 1) {
        $reviewStatus = "Pass"
        $riskLevel = "Low"
    }

    $report = @{
        ReportId = "SSS-$(Get-Date -Format 'yyyyMMdd')-$(Get-Random -Maximum 9999)"
        ScanTime = $timestamp
        ScanScope = $Scope
        ScanFileCount = $fileCount
        ReviewStatus = $reviewStatus
        ThreatScore = $script:threatScore
        RiskLevel = $riskLevel
        Threats = $script:threats
        Summary = @{
            Critical = ($script:threats | Where-Object { $_.Severity -eq "Critical" }).Count
            High = ($script:threats | Where-Object { $_.Severity -eq "High" }).Count
            Medium = ($script:threats | Where-Object { $_.Severity -eq "Medium" }).Count
            Low = ($script:threats | Where-Object { $_.Severity -eq "Low" }).Count
        }
    }

    return $report
}

function Output-Report {
    param($Report)

    Write-ColorOutput ""
    Write-ColorOutput "========== Skill Security Scan Report ==========" "Yellow"
    Write-ColorOutput "Report ID: $($Report.ReportId)" "White"
    Write-ColorOutput "Scan Time: $($Report.ScanTime)" "White"
    Write-ColorOutput "Scan Scope: $($Report.ScanScope)" "White"
    Write-ColorOutput "Files Scanned: $($Report.ScanFileCount)" "White"
    Write-ColorOutput "Threat Score: $($Report.ThreatScore)" "White"
    Write-ColorOutput "Risk Level: $($Report.RiskLevel)" "White"
    Write-ColorOutput "Review Status: $($Report.ReviewStatus)" "White"
    Write-ColorOutput "=================================================" "Yellow"
    Write-ColorOutput ""

    if ($Report.Threats.Count -gt 0) {
        Write-ColorOutput "Threats Found:" "Red"
        foreach ($threat in $Report.Threats) {
            $color = switch ($threat.Severity) {
                "Critical" { "Red" }
                "High" { "Magenta" }
                "Medium" { "Yellow" }
                "Low" { "Green" }
            }
            Write-ColorOutput "  [$($threat.Severity)] $($threat.RuleId) - $($threat.File):$($threat.Line)" $color
            Write-ColorOutput "    $($threat.Description)" "Gray"
        }
    } else {
        Write-ColorOutput "No security threats found" "Green"
    }

    if ($Format -eq "json") {
        $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $Output -Encoding UTF8
        Write-ColorOutput ""
        Write-ColorOutput "Report saved to: $Output" "Cyan"
    }
}

function Main {
    Write-ColorOutput "Starting Skill Security Scan..." "Green"
    Write-ColorOutput "Scan Scope: $Scope" "Cyan"
    Write-ColorOutput ""

    Scan-Directory -Directory $Scope

    $report = Generate-Report

    Output-Report -Report $report

    if ($FailOnHigh -and ($report.ReviewStatus -eq "Reject" -or $report.RiskLevel -eq "High")) {
        Write-ColorOutput ""
        Write-ColorOutput "X Scan failed: High or Critical threats found" "Red"
        exit 1
    }

    if ($report.ReviewStatus -eq "Reject") {
        Write-ColorOutput ""
        Write-ColorOutput "X Scan failed: Critical threats found, auto-rejected" "Red"
        exit 1
    }

    Write-ColorOutput ""
    Write-ColorOutput "V Scan completed successfully" "Green"
    exit 0
}

Main

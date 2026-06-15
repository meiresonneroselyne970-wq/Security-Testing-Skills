# Skill Security Scanner - PowerShell Version
# Version: 1.1.0
# Purpose: Auto scan skill files for security threats

param(
    [string]$Scope = "skills/",
    [string]$Output = "skill-security-report.json",
    [string]$Format = "json",
    [switch]$FailOnHigh,
    [switch]$Verbose
)

# Config
$ErrorActionPreference = "Stop"
$script:threats = @()
$script:threatScore = 0

# Color output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Add threat
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
    
    # Calculate threat score
    switch ($Severity) {
        "Critical" { $script:threatScore += 10 }
        "High" { $script:threatScore += 7 }
        "Medium" { $script:threatScore += 4 }
        "Low" { $script:threatScore += 1 }
    }
}

# Scan file
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
        
        # Skip documentation patterns
        if ($line -match "example|示例|demo|sample|template|文档|说明|注释|Example|Sample|Demo") {
            continue
        }
        
        # T1 - Malicious command injection
        if ($line -match "exec\(|system\(|popen\(|subprocess|os\.system|child_process") {
            Add-Threat -RuleId "T1.1" -Category "Malicious Command" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "System command execution function detected" `
                -Recommendation "Remove system command execution functions, use safe alternatives"
        }
        
        if ($line -match "rm -rf|rmdir /s|del /f|unlink|rmdir|shutil\.rmtree") {
            Add-Threat -RuleId "T1.2" -Category "Malicious Command" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "File system destruction command detected" `
                -Recommendation "Remove file system destruction commands, use safe file operations"
        }
        
        if ($line -match "curl.*POST|wget.*POST|fetch.*POST|XMLHttpRequest|axios\.post") {
            Add-Threat -RuleId "T1.3" -Category "Malicious Command" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "Data exfiltration operation detected" `
                -Recommendation "Verify data transmission legitimacy, remove unnecessary network requests"
        }
        
        # T2 - Hidden malicious commands
        if ($line -match "[\u200b\u200c\u200d\uFEFF]") {
            Add-Threat -RuleId "T2.1" -Category "Hidden Command" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match "Zero-width character" `
                -Description "Zero-width character detected, may hide malicious commands" `
                -Recommendation "Remove zero-width characters, ensure code visibility"
        }
        
        # T3 - Sensitive information leakage
        if ($line -match "sk-[a-zA-Z0-9]{20,}") {
            # Check if it's a placeholder
            if ($line -match "sk-xxx|sk-你的key|sk-your-key|sk-example|sk-demo|sk-test|sk-sample") {
                continue
            }
            Add-Threat -RuleId "T3.1" -Category "Sensitive Info" -Severity "High" `
                -File $FilePath -Line $lineNum -Match "sk-****" `
                -Description "Hardcoded API Key detected" `
                -Recommendation "Move API Key to environment variables or key management service"
        }
        
        if ($line -match "Bearer\s+[a-zA-Z0-9._\-]{20,}") {
            # Check if it's a placeholder
            if ($line -match "Bearer xxx|Bearer your-token|Bearer example|Bearer demo|Bearer test") {
                continue
            }
            Add-Threat -RuleId "T3.2" -Category "Sensitive Info" -Severity "High" `
                -File $FilePath -Line $lineNum -Match "Bearer ****" `
                -Description "Hardcoded Bearer Token detected" `
                -Recommendation "Move Token to environment variables or key management service"
        }
        
        # T5 - Social engineering attacks
        if ($line -match "enter.*password|provide.*token|input.*api.*key") {
            Add-Threat -RuleId "T5.1" -Category "Social Engineering" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "Credential solicitation statement detected" `
                -Recommendation "Remove credential solicitation statements, use secure authentication"
        }
        
        if ($line -match "ignore.*warning|skip.*check|bypass.*security") {
            Add-Threat -RuleId "T5.4" -Category "Social Engineering" -Severity "Critical" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "Security bypass statement detected" `
                -Recommendation "Remove security bypass statements, respect security mechanisms"
        }
        
        # T6 - Dependency risks (skip for documentation files)
        if ($line -match "<script\s+src=") {
            # Skip if it's in a documentation file
            if ($FilePath -match "skills\\.*\.md$") {
                continue
            }
            Add-Threat -RuleId "T6.1" -Category "Dependency Risk" -Severity "Medium" `
                -File $FilePath -Line $lineNum -Match $matches[0] `
                -Description "External script reference detected" `
                -Recommendation "Verify external script source is trusted, use official CDN"
        }
    }
}

# Scan directory
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

# Generate report
function Generate-Report {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fileCount = (Get-ChildItem -Path $Scope -Filter "*.md" -Recurse).Count
    
    # Determine review status
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

# Output report
function Output-Report {
    param($Report)
    
    Write-ColorOutput "`n========== Skill Security Scan Report ==========" "Yellow"
    Write-ColorOutput "Report ID: $($Report.ReportId)" "White"
    Write-ColorOutput "Scan Time: $($Report.ScanTime)" "White"
    Write-ColorOutput "Scan Scope: $($Report.ScanScope)" "White"
    Write-ColorOutput "Files Scanned: $($Report.ScanFileCount)" "White"
    Write-ColorOutput "Threat Score: $($Report.ThreatScore)" "White"
    Write-ColorOutput "Risk Level: $($Report.RiskLevel)" "White"
    Write-ColorOutput "Review Status: $($Report.ReviewStatus)" "White"
    Write-ColorOutput "================================================`n" "Yellow"
    
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
    
    # Save report
    if ($Format -eq "json") {
        $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $Output -Encoding UTF8
        Write-ColorOutput "`nReport saved to: $Output" "Cyan"
    }
}

# Main flow
function Main {
    Write-ColorOutput "Starting Skill Security Scan..." "Green"
    Write-ColorOutput "Scan Scope: $Scope`n" "Cyan"
    
    # Execute scan
    Scan-Directory -Directory $Scope
    
    # Generate report
    $report = Generate-Report
    
    # Output report
    Output-Report -Report $report
    
    # Return result
    if ($FailOnHigh -and ($report.ReviewStatus -eq "Reject" -or $report.RiskLevel -eq "High")) {
        Write-ColorOutput "`nX Scan failed: High or Critical threats found" "Red"
        exit 1
    }
    
    if ($report.ReviewStatus -eq "Reject") {
        Write-ColorOutput "`nX Scan failed: Critical threats found, auto-rejected" "Red"
        exit 1
    }
    
    Write-ColorOutput "`nV Scan completed successfully" "Green"
    exit 0
}

# Execute main flow
Main

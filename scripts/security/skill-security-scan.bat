@echo off
REM Skill Security Scanner — Batch Version
REM Version: 2.2.0 (Added Incremental Scan & Inline Ignore)
REM Part of AI DevSecOps Pipeline (skill-security-scan.yml)
REM Purpose: Auto scan skill files for security threats
REM Aligned with ci-scan.sh v2.2.0 rule set

setlocal enabledelayedexpansion

echo ==========================================
echo Skill Security Scanner v2.2.0
echo ==========================================
echo.

REM 检查 PowerShell 是否可用
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 PowerShell
    exit /b 1
)

REM 执行 PowerShell 脚本
powershell -ExecutionPolicy Bypass -File "%~dp0skill-security-scan.ps1" %*

REM 检查执行结果
if %errorlevel% neq 0 (
    echo.
    echo ❌ 扫描失败
    exit /b 1
) else (
    echo.
    echo ✅ 扫描完成
    exit /b 0
)

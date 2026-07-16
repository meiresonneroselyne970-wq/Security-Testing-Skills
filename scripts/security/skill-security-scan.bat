@echo off
REM Skill Security Scanner - 批处理版本
REM 版本: 2.1.0
REM Part of AI DevSecOps Pipeline (skill-security-scan.yml)
REM 用途: 自动扫描 skill 文件，检测安全威胁

setlocal enabledelayedexpansion

echo ==========================================
echo Skill 安全扫描器 v2.1.0
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

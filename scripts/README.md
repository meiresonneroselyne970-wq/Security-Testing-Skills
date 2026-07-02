# Skill 安全扫描工具

企业级 Skill 安全扫描工具，自动检测 skill 文件中的恶意代码、隐藏危险指令和安全违规。

---

## 工具列表

| 工具 | 用途 | 使用场景 |
|------|------|----------|
| `skill-security-scan.ps1` | PowerShell 扫描脚本 | Windows 本地扫描 |
| `skill-security-scan.bat` | 批处理启动脚本 | Windows 快速启动 |
| `skill-security-scan.yml` | GitHub Actions 配置 | CI/CD 自动扫描 |

---

## 快速开始

### Windows 本地扫描

```powershell
# 扫描 skills 目录
.\scripts\skill-security-scan.ps1 -Scope skills/

# 扫描 .claude/skills 目录
.\scripts\skill-security-scan.ps1 -Scope .claude/skills/

# 扫描单个文件
.\scripts\skill-security-scan.ps1 -Scope skills/card.md

# 生成 JSON 报告
.\scripts\skill-security-scan.ps1 -Scope skills/ -Output report.json

# 高危时失败
.\scripts\skill-security-scan.ps1 -Scope skills/ -FailOnHigh
```

### 批处理启动

```cmd
# 扫描 skills 目录
scripts\skill-security-scan.bat -Scope skills/

# 扫描 .claude/skills 目录
scripts\skill-security-scan.bat -Scope .claude/skills/
```

### CI/CD 集成

项目已配置 GitHub Actions，会在以下情况自动扫描：

1. **Push**: 推送代码到 `skills/` 或 `.claude/skills/` 目录
2. **Pull Request**: 创建或更新 PR 涉及 skill 文件
3. **手动触发**: 在 GitHub Actions 页面手动运行

---

## 扫描规则

### T1 — 恶意指令注入（严重）

- T1.1: 系统命令执行
- T1.2: 文件系统破坏
- T1.3: 网络外传数据
- T1.4: 反向 Shell
- T1.5: 权限提升

### T2 — 隐藏危险指令（严重）

- T2.1: 零宽字符
- T2.2: 隐藏 Unicode
- T2.3: 注释中的指令

### T3 — 敏感信息泄露（高危）

- T3.1: API Key 硬编码
- T3.2: Token 硬编码
- T3.3: 密码硬编码

### T4 — 权限越界（高危）

- T4.1: 文件系统写入
- T4.2: 文件系统删除
- T4.3: 网络请求

### T5 — 社会工程攻击（严重）

- T5.1: 凭据诱导
- T5.2: 紧急诱导
- T5.3: 权限诱导

### T6 — 依赖与供应链（中危）

- T6.1: 外部脚本引用
- T6.2: CDN 引用
- T6.3: 未锁定版本

### T7 — 合规性违规（中危）

- T7.1: 数据收集声明缺失
- T7.2: 用户同意缺失

---

## 审核决策

| 威胁分数 | 风险等级 | 审核决策 |
|----------|----------|----------|
| ≥ 12 | 🔴 严重 | 自动拒绝 |
| 8 - 11 | 🟠 高危 | 需人工审核 |
| 4 - 7 | 🟡 中危 | 需人工审核 |
| 1 - 3 | 🟢 低危 | 自动通过 |
| 0 | ✅ 安全 | 自动通过 |

---

## 报告格式

扫描完成后会生成 JSON 格式的报告，包含以下信息：

```json
{
  "ReportId": "SSS-20240122-1234",
  "ScanTime": "2024-01-22 10:00:00",
  "ScanScope": "skills/",
  "ScanFileCount": 7,
  "ReviewStatus": "通过",
  "ThreatScore": 0,
  "RiskLevel": "安全",
  "Threats": [],
  "Summary": {
    "Critical": 0,
    "High": 0,
    "Medium": 0,
    "Low": 0
  }
}
```

---

## 集成指南

### Git Pre-commit Hook

创建 `.git/hooks/pre-commit` 文件：

```bash
#!/bin/bash
echo "Running skill security scan..."
powershell -ExecutionPolicy Bypass -File scripts/security/skill-security-scan.ps1 -Scope staged -FailOnHigh

if [ $? -ne 0 ]; then
    echo "❌ Skill security scan failed"
    exit 1
fi

echo "✅ Skill security scan passed"
```

### VS Code 集成

在 `.vscode/tasks.json` 中添加：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Skill Security Scan",
      "type": "shell",
      "command": "powershell",
      "args": ["-ExecutionPolicy", "Bypass", "-File", "scripts/security/skill-security-scan.ps1", "-Scope", "skills/"],
      "group": "test",
      "problemMatcher": []
    }
  ]
}
```

### npm scripts

在 `package.json` 中添加：

```json
{
  "scripts": {
    "security:scan": "powershell -ExecutionPolicy Bypass -File scripts/security/skill-security-scan.ps1 -Scope skills/",
    "security:scan:ci": "powershell -ExecutionPolicy Bypass -File scripts/security/skill-security-scan.ps1 -Scope skills/ -FailOnHigh"
  }
}
```

---

## 白名单配置

### CDN 白名单

以下 CDN 被认为是安全的：

- `cdnjs.cloudflare.com`
- `unpkg.com`
- `jsdelivr.net`
- `cdn.jsdelivr.net`

### 模式白名单

以下模式被认为是安全的：

- `console.log` - 调试日志
- `Math.random` - 随机数生成
- `Date.now` - 时间戳

---

## 故障排除

### 问题：PowerShell 执行策略错误

**解决方案**：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题：找不到脚本文件

**解决方案**：

确保在项目根目录下运行脚本：

```powershell
cd C:\Users\Pc\Desktop\卡片模板\card-template
.\scripts\skill-security-scan.ps1 -Scope skills/
```

### 问题：扫描速度慢

**解决方案**：

1. 减少扫描范围
2. 使用 `-Scope` 参数指定目录
3. 排除不必要的文件

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2024-01-22 | 初始版本 |

---

## 维护者

MiMoCode Security Team

---

## 许可证

内部使用，未经授权不得外传。

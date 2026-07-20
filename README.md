# AI DevSecOps Pipeline — Skill Security Scanner

企业级 AI Skill 安全扫描管道，6 个并行安全门禁覆盖凭据泄露、提示词注入、RCE 防御、SAST、CodeQL 全维度检测。

---

## 管道架构

```
AI DevSecOps Pipeline
├── 🔑 Secrets Scan        (TruffleHog 增量扫描)
├── 💉 Prompt Injection    (提示词注入/越狱检测 + 白名单)
├── 🛑 Execution Sandbox   (Bandit + ShellCheck + JS 系统调用)
├── 🐛 SAST Analysis       (Semgrep + ci-scan.sh 内部扫描)
├── 🧠 CodeQL Analysis     (JS/TS + Python 矩阵并行)
└── 🚨 Failure Report      (聚合通知：仅发一条 PR 评论)
```

## 触发条件

| 事件 | 条件 |
|------|------|
| Push | `main` / `master` / `byl-v1.0.0` 分支 + 命中扫描路径 |
| Pull Request | 同上分支 & 路径 |
| Schedule | 每周四 21:31 (UTC+8) |
| Manual | `workflow_dispatch` |

## 快速开始

### 本地扫描

```bash
# Linux / macOS / CI（全量扫描）
bash scripts/security/ci-scan.sh --scope skills --scope .claude/skills --fail-on-high

# 增量扫描（仅扫描 PR 变更文件）
bash scripts/security/ci-scan.sh --scope skills --incremental --base origin/main --fail-on-high

# 生成 JSON 报告
bash scripts/security/ci-scan.sh --scope skills --format json --output report.json
```

### Windows PowerShell

```powershell
.\scripts\security\skill-security-scan.ps1 -Scope skills/,.claude/skills/ -FailOnHigh
.\scripts\security\skill-security-scan.ps1 -Scope skills/ -Incremental -BaseBranch origin/main
```

### Pre-commit Hook

```bash
bash scripts/security/pre-commit-hook.sh
```

## 目录结构

```
.
├── .github/workflows/
│   └── skill-security-scan.yml   # AI DevSecOps 管道定义
├── .claude/skills/
│   ├── security-audit.md         # 企业级安全审计（OWASP/CWE/GDPR/等保2.0）
│   ├── skill-security-policy.md  # 安全策略定义与管道架构文档
│   ├── skill-security-scanner.md # T1-T7 威胁检测规则引擎
│   ├── skill-manager.md          # Skill 分析·提取·分类·打包管理器
│   ├── gitee-repo.md             # Gitee 仓库管理（与 skill-manager 联动）
│   └── analyze-skills.py         # Skill 结构化分析脚本
├── scripts/security/
│   ├── ci-scan.sh                # Bash 安全扫描器 (v2.2.0)
│   ├── skill-security-scan.ps1   # PowerShell 安全扫描器 (v2.2.0)
│   ├── skill-security-scan.bat   # Windows CMD 安全扫描器
│   ├── pre-commit-hook.sh        # Git Pre-commit 钩子
│   └── sandbox_sdk.py            # 沙箱 SDK
├── .security-whitelist.yml       # 白名单配置
└── README.md
```

## 威胁检测规则 (T1-T7)

| 类别 | 威胁 | 等级 |
|------|------|------|
| T1 | 恶意指令注入（命令执行、文件破坏、外传数据、反向Shell） | 🔴 严重 |
| T2 | 隐藏危险指令（零宽字符、越狱、注释注入、编码绕过） | 🔴 严重 |
| T3 | 敏感信息泄露（API Key、Token、密码、私钥、内网地址） | 🟠 高危 |
| T4 | 权限越界（文件写入、进程创建、环境变量修改） | 🟠 高危 |
| T5 | 社会工程攻击（凭据诱导、紧急诱导、安全规避） | 🔴 严重 |
| T6 | 依赖与供应链风险（外部脚本、CDN、未锁定版本） | 🟡 中危 |
| T7 | 合规性违规（隐私政策、用户同意、审计日志缺失） | 🟡 中危 |

## 风险评分

| 威胁分数 | 风险等级 | 审核决策 |
|----------|----------|----------|
| ≥ 12 | 🔴 严重 | 自动拒绝 |
| 8 - 11 | 🟠 高危 | 需人工审核 |
| 4 - 7 | 🟡 中危 | 需人工审核 |
| 1 - 3 | 🟢 低危 | 自动通过 |
| 0 | ✅ 安全 | 自动通过 |

## 白名单

[`.security-whitelist.yml`](.security-whitelist.yml) 支持两类豁免：

- **file_whitelist** — 跳过整个文件扫描（适用于文档类文件含代码示例）
- **pattern_whitelist** — 行级豁免（匹配行含 `示例`、`example` 等关键词时放行）

内联豁免：在代码行末尾添加 `<!-- sec-ignore: T1.1 -->` 或 `<!-- sec-ignore: ALL -->`。

## 支持的扫描工具

| 工具 | 用途 | 管道 Job |
|------|------|----------|
| TruffleHog | 凭证扫描 | `secrets-audit` |
| Python 自研脚本 | 提示词注入检测 | `prompt-security` |
| Bandit | Python SAST | `execution-gate` |
| ShellCheck | Bash SAST | `execution-gate` |
| Semgrep | 多语言 SAST | `sast-analysis` |
| ci-scan.sh | 内部 T1-T7 扫描 | `sast-analysis` |
| CodeQL | 语义级深度分析 | `codeql-analysis` |

---

**版本**: 2.2.0 | **维护者**: card-template Security Team | **最后更新**: 2026-07

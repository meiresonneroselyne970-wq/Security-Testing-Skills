---
name: skill-security-policy
description: Skill 安全策略定义，包含 AI DevSecOps 管道架构、威胁等级、安全规则、白名单管理、应急响应和合规要求。
---

# skill-security-policy — Skill 安全策略

**版本**: 2.0.0
**生效日期**: 2026-07-16
**适用范围**: 所有 skill 文件（`skills/`、`.claude/skills/`、`cards/`、`scripts/`）

---

## 1. 安全目标

### 1.1 核心目标

- **零容忍**: 对恶意指令、隐藏危险代码、硬编码凭据零容忍
- **纵深防御**: 5 层安全门禁并行扫描，单一入口、多重覆盖
- **预防为主**: 在 skill 上架前拦截所有安全威胁
- **快速响应**: 发现安全问题后立即处理，支持单 Job 独立重试

### 1.2 具体目标

1. 防止恶意代码执行（RCE 防御）
2. 防止硬编码凭据泄露（TruffleHog）
3. 防止提示词注入与越狱（Prompt Audit）
4. 防止权限越界与沙箱逃逸
5. 确保供应链安全（依赖扫描）
6. 确保代码质量合规（CodeQL / Semgrep）

---

## 2. AI DevSecOps 管道架构

### 2.1 管道概览

采用**单文件、多并行 Job** 架构（[skill-security-scan.yml](../../.github/workflows/skill-security-scan.yml)），1 个 Workflow 包含 6 个并行 Job + 1 个聚合通知：

```
AI DevSecOps Pipeline
├── 🔑 Secrets Scan        (TruffleHog 增量扫描)
├── 💉 Prompt Injection    (提示词注入/越狱检测 + 白名单)
├── 🛑 Execution Sandbox   (Bandit + ShellCheck + JS 系统调用)
├── 🐛 SAST Analysis       (Semgrep + ci-scan.sh 内部扫描)
├── 🧠 CodeQL Analysis     (JS/TS + Python 矩阵并行)
└── 🚨 Failure Report      (聚合通知：仅发一条 PR 评论)
```

### 2.2 触发条件

| 事件 | 触发条件 |
|------|----------|
| **Push** | `main` / `master` / `byl-v1.0.0` 分支，且变更文件命中 `skills/**`、`.claude/skills/**`、`cards/**`、`scripts/**` |
| **Pull Request** | 同上分支 & 路径 |
| **Schedule** | 每周四 21:31 (UTC+8)，全量扫描 |
| **Manual** | `workflow_dispatch` 手动触发 |

### 2.3 各 Job 详细职责

| Job | 工具 | 扫描范围 | 失败行为 |
|-----|------|----------|----------|
| `secrets-audit` | TruffleHog | 增量 diff（`MERGE_BASE..HEAD`） | 发现已验证凭据即失败 |
| `prompt-security` | Python 自研脚本 | `skills/` `.claude/skills/` 中的文本文件 | 命中可疑模式即失败 |
| `execution-gate` | Bandit + ShellCheck + grep | Python/JS/Shell 系统调用拦截 | 任一子步骤失败即失败 |
| `sast-analysis` | Semgrep + ci-scan.sh | `skills/` `.claude/skills/` | 高危规则命中即失败 |
| `codeql-analysis` | GitHub CodeQL | 全仓库 JS/TS + Python | 按 CodeQL 默认规则 |
| `pr-failure-notification` | github-script | — | 仅 PR 事件 + 前序 Job 有失败时触发 |

### 2.4 聚合通知机制

- **PR 页面**: 每个 Job 独立显示 ✓ / ✗，支持 `Re-run failed jobs` 单独重试
- **防刷屏**: `pr-failure-notification` 使用 `needs.*.result` 聚合监听，仅当前面任意 Job 失败时发送**一条** PR 评论
- **非 PR 事件**: push / schedule / workflow_dispatch 不发送 PR 评论，直接看 Actions 页面

---

## 3. 安全等级定义

### 3.1 威胁等级

| 等级 | 标记 | 定义 | 响应时间 |
|------|------|------|----------|
| 严重 | 🔴 | 可导致系统完全失控 | 立即处理 |
| 高危 | 🟠 | 可导致严重安全事件 | 24 小时内 |
| 中危 | 🟡 | 可导致安全风险 | 1 周内 |
| 低危 | 🟢 | 轻微安全影响 | 1 月内 |

### 3.2 风险等级

| 等级 | 威胁分数 | 审核决策 |
|------|----------|----------|
| 严重 | ≥ 12 | 自动拒绝 |
| 高危 | 8 - 11 | 需人工审核 |
| 中危 | 4 - 7 | 需人工审核 |
| 低危 | 1 - 3 | 自动通过 |
| 安全 | 0 | 自动通过 |

---

## 4. 安全规则

### 4.1 绝对禁止（红线）

以下行为绝对禁止，发现即拒绝：

1. **恶意指令注入**
   - 系统命令执行（`subprocess`、`os.system`、`child_process`）
   - 文件系统破坏
   - 反向 Shell
   - 权限提升

2. **提示词注入与越狱**
   - `ignore previous instructions` 及变体
   - `system prompt bypass`
   - `DAN` 越狱模式
   - `reveal your system prompt`
   - 开发者模式绕过（`developer mode enabled`）

3. **隐藏危险指令**
   - 零宽字符隐藏
   - Unicode 控制字符
   - 注释中的恶意指令
   - Base64 / 十六进制编码绕过

4. **社会工程攻击**
   - 凭据诱导
   - 诱使忽略安全提醒
   - 伪造系统消息

### 4.2 严格限制

以下行为需严格审查：

1. **敏感信息处理**
   - 硬编码凭据（API Key、Token、密码）
   - 内网地址暴露（`10.x`、`172.16-31.x`、`192.168.x`）
   - 数据库连接串

2. **权限需求**
   - 文件系统写入
   - 网络请求（`curl`、`wget`、`fetch`）
   - 进程创建（`spawn`、`fork`、`exec`）

3. **外部依赖**
   - 外部脚本引用
   - CDN 引用
   - 未锁定版本（`latest`、`*`、`^`）

### 4.3 允许使用

以下行为允许使用，但需声明用途：

1. **调试工具**: `console.log`、`debugger`（开发环境）
2. **标准库函数**: `Math.random`、`Date.now`、`JSON.parse/stringify`
3. **官方 CDN**: `cdnjs.cloudflare.com`、`unpkg.com`、`jsdelivr.net`

---

## 5. 安全扫描工具栈

### 5.1 工具清单

| 工具 | 类型 | 用途 | 运行方式 |
|------|------|------|----------|
| **TruffleHog** | 凭证扫描 | 检测硬编码的 API Key、Token、私钥 | 原生安装，增量 Git 扫描 |
| **Bandit** | Python SAST | Python 代码静态安全分析 | `pip install` + 原生 CLI |
| **Semgrep** | 多语言 SAST | 安全审计 + 密钥检测规则集 | `pip install` + 原生 CLI |
| **ShellCheck** | Shell SAST | Bash 脚本语法与安全漏洞 | Action `ludeeus/action-shellcheck` |
| **CodeQL** | 高级语义分析 | JS/TS + Python 深度代码分析 | `github/codeql-action` |
| **ci-scan.sh** | 内部扫描器 | Skill 文件威胁分类 T1-T7 评分 | 本地 Bash 脚本 |
| **Prompt Audit** | 注入检测 | 提示词注入与越狱模式匹配 | Python 内联脚本 + `.security-whitelist.yml` |
| **JS System Call Check** | RCE 防御 | 拦截 `child_process`、`execSync` 等 | `grep` 模式匹配 |

### 5.2 为什么用原生 CLI 而非封装 Action

- **Bandit**: `PyCQA/bandit-action@v1` 不支持 `args` 参数传入 → 改用 `pip install bandit && bandit -r`
- **Semgrep**: `semgrep/semgrep-action@v1` 不支持 `path` 参数指定目录（默认全仓库扫描）→ 改用 `pip install semgrep && semgrep scan`
- 原生方式参数传递更直接，执行速度更快，版本控制更灵活

---

## 6. 白名单管理

### 6.1 白名单文件

白名单配置存储在仓库根目录 [`.security-whitelist.yml`](../../.security-whitelist.yml)，包含两类豁免：

- **`file_whitelist`**: 跳过整个文件的扫描（如文档类 skill 包含代码示例属正常行为）
- **`pattern_whitelist`**: 行级豁免，当匹配行包含指定关键词（如 `示例`、`example`）时放行

### 6.2 当前白名单条目

| 文件 | 原因 |
|------|------|
| `.claude/skills/skill-manager.md` | 包含 Python `subprocess` 代码示例用于文档演示 |
| `.claude/skills/skill-security-scanner.md` | 安全检测规则定义文档，自身含威胁特征示例 |
| `.claude/skills/skill-security-policy.md` | 安全策略文档，含检测规则说明 |

### 6.3 白名单申请

申请白名单需提供：

1. 使用场景说明
2. 安全风险评估
3. 安全措施说明
4. 审批人签字

---

## 7. 审核流程

### 7.1 自动审核（CI/CD 管道）

```
Skill 提交
    ↓
5 个安全门禁并行扫描
    ├── 🔑 TruffleHog 凭证扫描
    ├── 💉 Prompt 注入检测
    ├── 🛑 沙箱执行门禁 (Bandit + ShellCheck + JS)
    ├── 🐛 SAST (Semgrep + ci-scan.sh)
    └── 🧠 CodeQL 语义分析
    ↓
┌─────────────────────────────────────────┐
│ 全部 Job 通过 ✅                         │
│ → 允许合并                               │
├─────────────────────────────────────────┤
│ 任意 Job 失败                            │
│ → 🚨 聚合通知 PR（仅一条评论）            │
│ → 开发者可按失败 Job 独立重试             │
└─────────────────────────────────────────┘
```

### 7.2 人工审核

触发条件（`ci-scan.sh` 威胁分数 4-11 且无红线威胁）：

1. **上下文分析**: 分析代码的合法用途
2. **风险评估**: 评估潜在安全风险
3. **修复建议**: 提供修复建议
4. **审核决策**: 通过/拒绝/需修改

### 7.3 审核记录

所有审核记录需保存：

- 审核时间
- 审核人员
- 扫描报告（可从 Artifact 下载 `skill-security-report.json`）
- 审核决策
- 修复记录

---

## 8. 应急响应

### 8.1 响应流程

```
发现安全问题
    ↓
立即下架 skill / 阻塞 PR
    ↓
通知相关人员
    ↓
分析问题原因
    ↓
修复安全问题
    ↓
重新审核上架 / 重跑管道
    ↓
总结经验教训
```

### 8.2 响应时间

| 威胁等级 | 响应时间 | 处理时间 |
|----------|----------|----------|
| 🔴 严重 | 立即 | 1 小时内 |
| 🟠 高危 | 1 小时内 | 24 小时内 |
| 🟡 中危 | 24 小时内 | 1 周内 |
| 🟢 低危 | 1 周内 | 1 月内 |

### 8.3 通知机制

| 威胁等级 | 通知范围 |
|----------|----------|
| 🔴 严重 | 安全团队 + 管理层 + 所有用户 |
| 🟠 高危 | 安全团队 + 管理层 |
| 🟡 中危 | 安全团队 |
| 🟢 低危 | 安全团队（邮件） |

---

## 9. 合规要求

### 9.1 法律法规

- 《网络安全法》
- 《数据安全法》
- 《个人信息保护法》
- GDPR（如适用）

### 9.2 行业标准

- OWASP Top 10
- CWE/SANS Top 25
- ISO 27001
- 等保 2.0

### 9.3 内部规范

- 代码安全规范
- 数据安全规范
- 访问控制规范

---

## 10. 培训与意识

### 10.1 培训内容

1. **安全基础知识**: 常见安全威胁、安全编码实践、安全工具使用
2. **Skill 安全专项**: Skill 安全规则、安全审核流程、应急响应流程、沙箱执行门禁原理
3. **案例分析**: 真实安全事件、攻击手法分析、防御措施总结

### 10.2 培训频率

- 新成员：入职培训
- 全员：每季度一次
- 专项：按需进行（安全规则重大更新时）

---

## 11. 持续改进

### 11.1 定期审查

- **每次 Push/PR**: 自动触发全管道扫描
- **每周四**: CodeQL + 安全管道定时全量扫描
- **月度**: 审查扫描结果趋势
- **季度**: 审查安全规则有效性、更新威胁模式库
- **年度**: 审查安全策略整体架构

### 11.2 规则更新

根据以下情况更新安全规则：

1. 新型攻击手法出现（如新的提示词注入变体）
2. 安全威胁态势变化
3. 法律法规更新
4. 行业标准变化（OWASP / CWE 更新）

### 11.3 工具升级

定期升级安全扫描工具：

1. 更新威胁规则库（Semgrep `p/security-audit`、`p/secrets` 规则集）
2. 优化扫描算法（ci-scan.sh 评分模型）
3. 更新 CodeQL 查询套件
4. 同步 TruffleHog 最新版本

---

## 12. 附录

### 12.1 术语表

| 术语 | 定义 |
|------|------|
| Skill | 可复用的 AI 指令模块（`.md` 文件或 `cards/*/` 目录） |
| 威胁 | 可能导致安全问题的行为或代码模式 |
| 漏洞 | 系统中的安全弱点 |
| 白名单 | `.security-whitelist.yml` 中允许豁免扫描的安全列表 |
| 红线 | 绝对禁止的行为（T1 恶意指令、T2 隐藏指令、T5 社会工程） |
| 沙箱执行门禁 | 拦截 `subprocess`、`child_process`、`os.system` 等系统调用 |
| 聚合通知 | 多个 Job 失败时仅发送一条 PR 评论，而非每个 Job 各发一条 |

### 12.2 相关文件

| 文件 | 说明 |
|------|------|
| [skill-security-scan.yml](../../.github/workflows/skill-security-scan.yml) | AI DevSecOps 管道 Workflow 定义 |
| [.security-whitelist.yml](../../.security-whitelist.yml) | 白名单配置文件 |
| [ci-scan.sh](../../scripts/security/ci-scan.sh) | 内部安全扫描脚本 |
| [skill-security-scanner.md](skill-security-scanner.md) | T1-T7 威胁检测规则详细定义 |
| [sandbox_sdk.py](../../scripts/security/sandbox_sdk.py) | 沙箱 SDK，安全的系统调用封装 |

### 12.3 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [TruffleHog Docs](https://github.com/trufflesecurity/trufflehog)
- [Semgrep Rules](https://semgrep.dev/r)
- [Bandit Docs](https://bandit.readthedocs.io/)

---

**维护者**: card-template Security Team
**最后更新**: 2026-07-16
**下次审查**: 2026-10-16

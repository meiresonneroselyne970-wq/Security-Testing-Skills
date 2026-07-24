---
name: skill-security-scanner
description: Skill 安全扫描器，检测 skill 文件中的恶意代码、隐藏危险指令和安全违规。支持 T1-T7 威胁分类，作为 AI DevSecOps 管道的内部 SAST 引擎运行。
---

# skill-security-scanner — Skill 安全扫描器

**版本**: 2.0.0
**安全等级**: 企业级
**适用场景**: Skill 上架审核、定期安全巡检、AI DevSecOps 管道集成

---

## Trigger

当用户提到以下任何一种情况时触发此 skill：

- skill 安全扫描 / skill 安全检查 / skill 安全审核
- skill 上架审核 / skill 发布检查
- 检查 skill 安全性 / 扫描恶意 skill
- skill security scan / skill security audit
- 防止恶意 skill / 检测危险 skill

---

## 扫描范围

默认扫描 `skills/` 目录下所有 `.md` 文件。用户可通过参数限定：

- 指定目录：`扫描 .claude/skills/ 下所有文件`
- 指定文件：`扫描 skills/card.md`
- 全量扫描：`扫描所有 skill 文件`

---

## 安全威胁分类

### T1 — 恶意指令注入（严重 / Critical）

**威胁描述**: Skill 中隐藏的恶意指令，可能诱导 AI 执行危险操作。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T1.1 | 系统命令执行 | `exec\(`、`system\(`、`popen\(`、`subprocess`、`os\.system`、`child_process` | 🔴 严重 |
| T1.2 | 文件系统破坏 | `rm` `-rf`、`rm` `dir` `/s`、`del` `/f`、`un` `link`、`rm` `dir`、`shutil\.rmtree` | 🔴 严重 |
| T1.3 | 网络外传数据 | `curl.*POST`、`wget.*POST`、`fetch.*POST`、`XMLHttpRequest`、`axios\.post` | 🔴 严重 |
| T1.4 | 反向 Shell | `bash` `-i`、`nc` `-e`、`nc` `at`、`so` `cat`、`/dev/` `tcp`、`mk` `fifo` | 🔴 严重 |
| T1.5 | 权限提升 | `su` `do`、`ch` `mod` `777`、`ch` `own`、`set` `uid`、`set` `gid` | 🔴 严重 |
| T1.6 | 环境变量窃取 | `process\.env`、`os\.environ`、`getenv`、`env\[` | 🟠 高危 |
| T1.7 | 编码绕过 | `atob\(`、`btoa\(`、`base64`、`eval\(`、`Function\(`、`new Function` | 🟠 高危 |
| T1.8 | 混淆代码 | `\\x[0-9a-f]{2}`、`\\u[0-9a-f]{4}`、`String\.fromCharCode`、`charCodeAt` | 🟡 中危 |

### T2 — 隐藏危险指令（严重 / Critical）

**威胁描述**: 通过特殊格式、注释或隐藏字符隐藏的危险指令。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T2.1 | 零宽字符 | `[\u200b\u200c\u200d\uFEFF]` | 🔴 严重 |
| T2.2 | 隐藏 Unicode | `[\u0000-\u001F]`（排除换行/tab） | 🔴 严重 |
| T2.3 | 注释中的指令 | `<!--.*-->` 包含 `exec`、`system`、`eval` | 🔴 严重 |
| T2.4 | HTML 实体编码 | `&#x[0-9a-f]+;`、`&#[0-9]+;` 包含危险字符 | 🟠 高危 |
| T2.5 | Base64 编码指令 | `base64` 附近包含 `de` `code`、`eval` | 🟠 高危 |
| T2.6 | 十六进制编码 | `0x[0-9a-f]+` 包含危险字符串 | 🟡 中危 |
| T2.7 | 拼接绕过 | 字符串拼接 `+` 或 `.` 包含 `exec`、`system` | 🟠 高危 |
| T2.8 | 变量覆盖 | `globalThis`、`window[`、`self[`、`global[` | 🟠 高危 |

### T3 — 敏感信息泄露（高危 / High）

**威胁描述**: Skill 中泄露的敏感信息。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T3.1 | API Key 硬编码 | `sk-[a-zA-Z0-9]{20,}`、`api[_-]?key[=:]\s*["']?[a-zA-Z0-9]{16,}` | 🟠 高危 |
| T3.2 | Token 硬编码 | `Bearer\s+[a-zA-Z0-9._\-]{20,}`、`ghp_[a-zA-Z0-9]{36}` | 🟠 高危 |
| T3.3 | 密码硬编码 | `password[=:]\s*["']?[^\s"']{6,}` | 🟠 高危 |
| T3.4 | 私钥泄露 | `-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY` | 🟠 高危 |
| T3.5 | 内网地址 | `10\.\d+\.\d+\.\d+`、`172\.(1[6-9]\|2\d\|3[01])\.\d+\.\d+`、`192\.168\.\d+\.\d+` | 🟡 中危 |
| T3.6 | 内部域名 | `\.(internal\|local\|corp\|intra)\.\w+` | 🟡 中危 |
| T3.7 | 数据库连接串 | `(mysql\|postgres\|mongodb\|redis)://[^:]+:[^@]+@` | 🟠 高危 |

### T4 — 权限越界（高危 / High）

**威胁描述**: Skill 申请超出其功能需要的权限。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T4.1 | 文件系统写入 | `writeFile`、`fs\.write`、`open\(.*w`、`fwrite`、`file_put_contents` | 🟠 高危 |
| T4.2 | 文件系统删除 | `un` `link`、`remove`、`delete`、`rm ` | 🟠 高危 |
| T4.3 | 网络请求 | `fetch\(`、`axios\(`、`request\(`、`http\.get`、`urllib` | 🟡 中危 |
| T4.4 | 进程创建 | `spawn`、`fork`、`exec`、`popen` | 🟠 高危 |
| T4.5 | 环境变量修改 | `process\.env\.\w+\s*=`、`os\.environ\[` | 🟡 中危 |
| T4.6 | 定时器滥用 | `setInterval`、`setTimeout`、`setImmediate` | 🟢 低危 |
| T4.7 | 无限循环风险 | `while\s*\(\s*true\s*\)`、`for\s*\(\s*;\s*;\s*\)` | 🟡 中危 |

### T5 — 社会工程攻击（严重 / Critical）

**威胁描述**: 通过 skill 诱导用户泄露敏感信息或执行危险操作。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T5.1 | 凭据诱导 | `请输 入.*密 码`、`输 入.*API.*Key`、`en ter.*pass word`、`pro vide.*to ken` | 🔴 严重 |
| T5.2 | 紧急诱导 | `立 即.*执 行`、`马 上.*运 行`、`ur gent`、`imme diately`、`AS AP` | 🟡 中危 |
| T5.3 | 权限诱导 | `请授予.*权限`、`需要.*管理员`、`require.*admin`、`need.*permission` | 🟠 高危 |
| T5.4 | 规避安全检测 | `忽 略.*警 告`、`跳 过.*检 查`、`ig nore.*warn ing`、`sk ip.*che ck` | 🔴 严重 |
| T5.5 | 伪造系统消息 | `系统.*通知`、`官方.*要求`、`system.*notice`、`official.*require` | 🔴 严重 |

### T6 — 依赖与供应链（中危 / Medium）

**威胁描述**: Skill 引用的外部依赖可能存在安全风险。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T6.1 | 外部脚本引用 | `<script\s+src=`、`import.*from.*http`、`require\(.*http` | 🟡 中危 |
| T6.2 | CDN 引用 | `cdn\.`、`unpkg\.`、`jsdelivr\.` | 🟡 中危 |
| T6.3 | 未锁定版本 | `latest`、`*`、`>=`、`^`、`~` | 🟡 中危 |
| T6.4 | 私有源 | `registry`、`npmrc`、`pip.*index` | 🟡 中危 |
| T6.5 | 可执行文件 | `\.exe`、`\.bat`、`\.cmd`、`\.ps1`、`\.sh`、`\.dll`、`\.so` | 🟠 高危 |

### T7 — 合规性违规（中危 / Medium）

**威胁描述**: Skill 违反安全合规要求。

| ID | 检测项 | 模式 | 威胁等级 |
|----|--------|------|----------|
| T7.1 | 数据收集声明缺失 | 无 `隐私政策`、`privacy` 相关说明 | 🟡 中危 |
| T7.2 | 用户同意缺失 | 无 `用户同意`、`consent` 相关说明 | 🟡 中危 |
| T7.3 | 数据保留说明缺失 | 无 `数据保留`、`retention` 相关说明 | 🟡 中危 |
| T7.4 | 审计日志缺失 | 无 `日志`、`log`、`audit` 相关说明 | 🟡 中危 |

---

## 执行流程

```
[1] 确定扫描范围
     ↓
[2] 初始化扫描环境
     ├── 加载威胁规则集 T1-T7
     ├── 加载白名单规则
     └── 初始化报告生成器
     ↓
[3] 静态分析阶段
     ├── Phase 1: 恶意指令扫描 (T1)
     │   └── 逐一运行 Grep，每个模式单独搜索
     ├── Phase 2: 隐藏指令扫描 (T2)
     │   └── 特殊字符检测 + 编码分析
     ├── Phase 3: 敏感信息扫描 (T3)
     │   └── 正则模式匹配
     ├── Phase 4: 权限分析 (T4)
     │   └── 语义分析 + 关键词匹配
     ├── Phase 5: 社会工程检测 (T5)
     │   └── NLP 模式匹配
     ├── Phase 6: 依赖分析 (T6)
     │   └── 引用提取 + 版本检查
     └── Phase 7: 合规检查 (T7)
         └── 结构分析 + 声明检查
     ↓
[4] 语义分析阶段
     ├── 分析指令上下文
     ├── 识别合法使用场景
     └── 排除误报
     ↓
[5] 风险评分
     ├── 计算威胁分数
     ├── 评估影响范围
     └── 生成风险等级
     ↓
[6] 审核决策
     ├── 自动通过 (无风险)
     ├── 需人工审核 (中风险)
     └── 自动拒绝 (高风险)
     ↓
[7] 生成报告
     ├── 威胁汇总
     ├── 详细分析
     ├── 审核建议
     └── 修复指导
```

---

## 扫描策略

### 深度扫描模式

对每个 skill 文件执行深度扫描：

```yaml
scan_strategy:
  # 第一层：表面扫描
  surface_scan:
    - 检查文件头信息
    - 提取元数据
    - 分析目录结构

  # 第二层：内容扫描
  content_scan:
    - 正则模式匹配
    - 关键词检测
    - 编码分析

  # 第三层：语义扫描
  semantic_scan:
    - 指令上下文分析
    - 意图识别
    - 权限需求分析

  # 第四层：行为模拟
  behavior_simulation:
    - 模拟执行流程
    - 分析潜在影响
    - 评估风险等级
```

### 白名单机制

以下情况可加入白名单：

```yaml
whitelist:
  # 合法使用场景
  legitimate_use:
    - T1.1: "用于代码生成的 exec 示例（需明确标注为示例）"
    - T4.3: "用于 API 调用的 fetch（需声明用途）"
    - T6.1: "引用官方 CDN（需在白名单列表中）"

  # 官方 CDN 白名单
  trusted_cdns:
    - "cdnjs.cloudflare.com"
    - "unpkg.com"
    - "jsdelivr.net"
    - "cdn.jsdelivr.net"

  # 安全模式
  safe_patterns:
    - "console.log"  # 调试日志
    - "Math.random"  # 随机数生成
    - "Date.now"     # 时间戳
```

---

## 风险评分

### 威胁分数计算

```
威胁分数 = 基础分 × 影响系数 × 利用难度系数
```

| 威胁等级 | 基础分 | 影响系数 | 利用难度系数 |
|----------|--------|----------|--------------|
| 🔴 严重 | 10 | 1.5 | 0.8 |
| 🟠 高危 | 7 | 1.2 | 0.9 |
| 🟡 中危 | 4 | 1.0 | 1.0 |
| 🟢 低危 | 1 | 0.8 | 1.2 |

### 风险等级映射

| 威胁分数 | 风险等级 | 审核决策 |
|----------|----------|----------|
| ≥ 12 | 🔴 严重 | 自动拒绝 |
| 8 - 11 | 🟠 高危 | 需人工审核 |
| 4 - 7 | 🟡 中危 | 需人工审核 |
| 1 - 3 | 🟢 低危 | 自动通过 |
| 0 | ✅ 安全 | 自动通过 |

---

## 审核决策

### 自动通过条件

满足以下所有条件可自动通过：

1. 无 T1（恶意指令）威胁
2. 无 T2（隐藏指令）威胁
3. 无 T5（社会工程）威胁
4. T3-T4 威胁分数 < 4
5. T6-T7 威胁分数 < 4

### 自动拒绝条件

满足以下任一条件自动拒绝：

1. 存在 T1（恶意指令）威胁
2. 存在 T2（隐藏指令）威胁
3. 存在 T5（社会工程）威胁
4. 威胁分数 ≥ 12

### 人工审核条件

不满足自动通过和自动拒绝条件的，需人工审核。

---

## 报告格式

```markdown
# Skill 安全审核报告

**报告编号**: SSS-YYYYMMDD-XXXX
**扫描时间**: YYYY-MM-DD HH:MM:SS
**扫描范围**: <目录/文件>
**扫描文件数**: N
**审核工具**: skill-security-scanner v1.0.0

---

## 审核结果

**审核状态**: ✅ 通过 / ⚠️ 需人工审核 / ❌ 拒绝
**威胁分数**: X.X / 15.0
**风险等级**: 🟢 低危 / 🟡 中危 / 🟠 高危 / 🔴 严重

---

## 威胁概览

| 威胁类别 | 发现数 | 威胁分数 |
|----------|--------|----------|
| T1 恶意指令 | 0 | 0 |
| T2 隐藏指令 | 0 | 0 |
| T3 敏感信息 | 2 | 2 |
| T4 权限越界 | 1 | 1 |
| T5 社会工程 | 0 | 0 |
| T6 依赖风险 | 0 | 0 |
| T7 合规违规 | 0 | 0 |

---

## 详细发现

### 1. 🟡 T3.5 — 内网地址暴露

- **文件**: `skills/card.md:403`
- **匹配**: `localhost:8800`
- **上下文**: 文档中的服务配置说明
- **威胁等级**: 🟡 中危
- **风险说明**: 内网地址暴露可能被用于探测内部服务
- **审核建议**: 确认为合法使用场景，添加至白名单
- **修复建议**: 使用环境变量管理服务地址

---

## 审核建议

### 自动审核

- ✅ 无恶意指令
- ✅ 无隐藏危险指令
- ✅ 无社会工程攻击

### 人工审核

- ⚠️ 内网地址暴露需确认用途
- ⚠️ 权限需求需评估合理性

---

## 修复指导

### 优先级 P0（必须修复）

无

### 优先级 P1（建议修复）

1. 将内网地址移至环境变量
2. 添加隐私政策声明

### 优先级 P2（可选修复）

无

---

## 附录

### A. 扫描配置

```yaml
scan_config:
  version: "1.0.0"
  rules_enabled: [T1, T2, T3, T4, T5, T6, T7]
  whitelist_enabled: true
  auto_approve_threshold: 4
  auto_reject_threshold: 12
  scan_depth: "deep"
```

### B. 白名单

```yaml
whitelist:
  cdns:
    - "cdnjs.cloudflare.com"
    - "unpkg.com"
    - "jsdelivr.net"
  patterns:
    - "console.log"
    - "Math.random"
```
```

---

## 工具使用

执行扫描时使用以下工具：

1. **Grep** — 对目标文件按正则模式搜索，是主要扫描手段
2. **Glob** — 确定扫描范围，列举目标文件
3. **Read** — 对 Grep 命中的上下文进行二次确认，排除误报
4. **Bash** — 检查文件编码、特殊字符

### 扫描命令示例

```bash
# 扫描所有 skill 文件（Linux / macOS / CI）
bash scripts/security/ci-scan.sh --scope skills

# 扫描单个文件
bash scripts/security/ci-scan.sh --scope skills/card.md

# 扫描 .claude/skills 目录
bash scripts/security/ci-scan.sh --scope .claude/skills

# 生成 JSON 报告
bash scripts/security/ci-scan.sh --scope skills --format json --output report.json

# Windows PowerShell
.\scripts\security\skill-security-scan.ps1 -Scope skills/
.\scripts\security\skill-security-scan.ps1 -Scope skills/ -Output report.json
```

---

## 误报排除

以下情况不计入威胁：

### 文档与示例

- README / 文档中作为**示例**出现的代码片段
- 注释中明确标注为示例的代码
- 测试用例中的 mock 数据

### 合法使用场景

- 代码生成 skill 中的 exec 示例（需明确标注）
- API 调用 skill 中的 fetch 示例（需声明用途）
- 官方 CDN 引用（需在白名单中）

### 安全模式

- 使用 `esc()` 函数转义的用户输入
- 使用 `DOMPurify` 消毒的 HTML
- 使用 `textContent` 替代 `innerHTML`

---

## CI/CD 集成

本扫描器作为 **AI DevSecOps Pipeline** ([skill-security-scan.yml](../../.github/workflows/skill-security-scan.yml)) 的 SAST 引擎运行。

### 管道架构（单文件 6 Job 并行）

```
AI DevSecOps Pipeline
├── 🔑 Secrets Scan        (TruffleHog 增量扫描)
├── 💉 Prompt Injection    (提示词注入/越狱检测 + 白名单)
├── 🛑 Execution Sandbox   (Bandit + ShellCheck + JS 系统调用)
├── 🐛 SAST Analysis       (Semgrep + ci-scan.sh 本扫描器)  ← 本 Skill
├── 🧠 CodeQL Analysis     (JS/TS + Python 矩阵并行)
└── 🚨 Failure Report      (聚合通知：仅发一条 PR 评论)
```

### 在管道中的角色

本扫描器在 `sast-analysis` Job 中运行，与 Semgrep 并行执行。

**PR 事件**自动启用增量扫描（只扫描变更的 `.md` 文件），**Push/Schedule/手动**执行全量扫描：

```yaml
sast-analysis:
  name: 🐛 Semgrep & Internal Scan
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0  # 增量扫描需要完整 git 历史
    - name: Semgrep Scan
      run: |
        python -m pip install semgrep
        semgrep scan --config "p/security-audit" --config "p/secrets" skills/ .claude/skills/
    - name: Internal Skill Security Scanner
      run: |
        chmod +x scripts/security/ci-scan.sh
        if [[ "${{ github.event_name }}" == "pull_request" ]]; then
          # PR: 增量扫描 — 仅扫描相对 base 分支变更的 .md 文件
          bash scripts/security/ci-scan.sh \
            --scope skills --scope .claude/skills \
            --format json --output skill-security-report.json --fail-on-high \
            --incremental --base "origin/${{ github.base_ref }}"
        else
          # Push/Schedule/手动: 全量扫描
          bash scripts/security/ci-scan.sh \
            --scope skills --scope .claude/skills \
            --format json --output skill-security-report.json --fail-on-high
        fi
    - name: Upload Security Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: skill-security-report
        path: skill-security-report.json
        retention-days: 14
```

### 增量扫描 (`--incremental`)

v2.2.0 新增。通过 `git diff --name-only <base>...HEAD` 仅扫描 PR 中变更的 `.md` 文件，解决全量扫描的历史包袱和性能问题。

- **无 `.md` 变更时**：毫秒级通过，不遍历文件系统
- **CI 用法**：`--incremental --base "origin/${{ github.base_ref }}"`

### 内联豁免 (`<!-- sec-ignore -->`)

v2.2.0 新增。在 Markdown 文件中加注释即可精准豁免指定行，无需修改 `.security-whitelist.yml`：

```markdown
# 豁免单个规则
`rm -rf /tmp/cache` <!-- sec-ignore: T1.2 -->

# 豁免多个规则
export API_KEY="sk-abc123" <!-- sec-ignore: T3.1, T1.1 -->

# 豁免所有规则
sudo systemctl restart nginx <!-- sec-ignore: ALL -->
```

### 触发条件

| 事件 | 条件 |
|------|------|
| Push | `main`/`master`/`byl-v1.0.0` 分支 + 命中 `skills/**`、`.claude/skills/**`、`cards/**`、`scripts/**` |
| Pull Request | 同上分支 & 路径 |
| Schedule | 每周四 21:31 (UTC+8) 全量扫描 |
| Manual | `workflow_dispatch` 手动触发 |

### 失败处理

- **独立重试**: 每个 Job 失败可单独 `Re-run failed jobs`，无需重跑全管道
- **报告留存**: `skill-security-report.json` 作为 Artifact 保留 14 天，可从 Actions 页面下载
- **聚合通知**: `pr-failure-notification` Job 仅在 PR 事件 + 前序任意 Job 失败时，统一发送**一条** PR 评论，避免刷屏

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit (由 scripts/security/pre-commit-hook.sh 调用)

echo "Running skill security scan..."
bash scripts/security/ci-scan.sh --scope skills --scope .claude/skills --fail-on-high

if [ $? -ne 0 ]; then
    echo "❌ Skill security scan failed. Please fix issues before committing."
    exit 1
fi

echo "✅ Skill security scan passed."
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.1.0 | 2026-07-16 | 新增增量扫描 (`--incremental`) 和内联豁免 (`<!-- sec-ignore -->`)，PR 事件自动启用增量模式 |
| 2.0.0 | 2026-07-16 | CI/CD 集成更新：迁移至 AI DevSecOps Pipeline 单文件多并行架构；管道触发条件、聚合通知、独立重试机制 |
| 1.0.0 | 2024-01-22 | 初始版本：T1-T7 威胁检测规则 |

---

**维护者**: 炎图科技
**最后更新**: 2026-07-16
**下次审查**: 2026-10-16

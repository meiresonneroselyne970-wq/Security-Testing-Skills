---
name: security-audit
description: 企业级安全审计工具，扫描文件检测敏感信息泄露、安全隐患和合规风险，输出结构化审计报告。覆盖 OWASP Top 10、CWE/SANS Top 25、GDPR、等保 2.0。
---

# security-audit — 安全审计

**版本**: 2.1.0
**合规标准**: OWASP Top 10、CWE/SANS Top 25、GDPR、等保 2.0
**适用场景**: 代码提交前检查、定期安全巡检、合规审计、AI DevSecOps 管道集成

---

## Trigger

当用户提到以下任何一种情况时触发此 skill：

- 安全审计 / 安全扫描 / 安全检查 / 安全评估
- 扫描敏感信息 / 检查泄露 / 数据泄露检查
- security audit / security scan / security assessment
- 检查 API key / 检查密码 / 检查凭据 / 检查密钥
- 审计报告 / 合规检查 / 等保检查
- 代码安全审查 / source code review
- 漏洞扫描 / vulnerability scan
- OWASP 检查 / CWE 检查

---

## 扫描范围

默认扫描项目根目录下所有文件。用户可通过参数限定：

- 指定目录：`扫描 src/ 下所有文件`
- 指定类型：`扫描所有 .md 文件`、`扫描所有 .js 文件`
- 全量扫描：`扫描整个项目`
- 排除目录：`扫描除 node_modules/ 外的所有文件`
- 深度扫描：`深度扫描所有文件`（包含二进制文件元数据）

### 默认排除目录

以下目录默认排除（除非用户明确指定）：

```
node_modules/
.git/
.svn/
.hg/
dist/
build/
__pycache__/
.venv/
vendor/
.cache/
tmp/
temp/
```

---

## 检测规则

### R1 — 硬编码凭据（严重 / Critical）

CWE-798: Use of Hard-coded Credentials

| ID | 检测项 | 模式 | 合规映射 |
|----|--------|------|----------|
| R1.1 | API Key 通用 | `sk-[a-zA-Z0-9]{20,}`、`api[_-]?key[=:]\s*["']?[a-zA-Z0-9]{16,}` | CWE-798 |
| R1.2 | Bearer Token | `Bearer\s+[a-zA-Z0-9._\-]{20,}` | CWE-798 |
| R1.3 | 密码明文 | `password[=:]\s*["']?[^\s"']{6,}`、`passwd[=:]`、`secret[=:]` | CWE-798, CWE-256 |
| R1.4 | 私钥 | `-----BEGIN\s+(RSA\s+|EC\s+|DSA\s+|OPENSSH\s+)?PRIVATE\s+KEY` | CWE-798 |
| R1.5 | AWS 凭据 | `AKIA[0-9A-Z]{16}` | CWE-798 |
| R1.6 | GitHub Token | `ghp_[a-zA-Z0-9]{36}`、`github_pat_[a-zA-Z0-9]{22,}`、`gho_[a-zA-Z0-9]{36}`、`ghu_[a-zA-Z0-9]{36}`、`ghs_[a-zA-Z0-9]{36}`、`ghr_[a-zA-Z0-9]{36}` | CWE-798 |
| R1.7 | 通用密钥赋值 | `(key|token|secret|credential|auth)[=:]\s*["'][a-zA-Z0-9._\-]{16,}["']` | CWE-798 |
| R1.8 | Slack Token | `xox[bpors]-[a-zA-Z0-9\-]{10,}` | CWE-798 |
| R1.9 | Google API Key | `AIza[0-9A-Za-z\-_]{35}` | CWE-798 |
| R1.10 | Stripe Key | `sk_live_[0-9a-zA-Z]{24,}`、`pk_live_[0-9a-zA-Z]{24,}` | CWE-798 |
| R1.11 | Azure Key | `[a-zA-Z0-9]{32}` (需结合上下文 `azure`/`ms` 关键词) | CWE-798 |
| R1.12 | Alibaba Cloud Key | `LTAI[a-zA-Z0-9]{12,20}` | CWE-798 |
| R1.13 | Tencent Cloud Key | `AKID[a-zA-Z0-9]{13,20}` | CWE-798 |
| R1.14 | Huawei Cloud Key | `a]bAK[A-Za-z0-9]{20,}` | CWE-798 |
| R1.15 | JWT Token | `eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*` | CWE-798 |
| R1.16 | SSH 私钥文件扩展名 | `.*\.(pem|key|p12|pfx|jks|keystore)` (文件名匹配) | CWE-798 |
| R1.17 | Database URL with Password | `(mysql|postgres|mongodb|redis|amqp)://[^:]+:[^@]+@` | CWE-798 |
| R1.18 | Hardcoded IP with Port | `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{2,5}` (排除文档示例) | CWE-798 |

### R2 — 内部 URL 与端点（高危 / High）

CWE-200: Exposure of Sensitive Information

| ID | 检测项 | 模式 | 合规映射 |
|----|--------|------|----------|
| R2.1 | 内网 IP | `10\.\d+\.\d+\.\d+`、`172\.(1[6-9]\|2\d\|3[01])\.\d+\.\d+`、`192\.168\.\d+\.\d+` | CWE-200 |
| R2.2 | localhost 端口 | `localhost:\d{2,5}`、`127\.0\.0\.1:\d{2,5}`、`0\.0\.0\.0:\d{2,5}` | CWE-200 |
| R2.3 | 数据库连接串 | `(mysql\|postgres\|mongodb\|redis\|amqp\|kafka)://\S+` | CWE-200 |
| R2.4 | 内部域名 | `\.(internal\|local\|corp\|intra\|priv\|test\|staging\|dev)\.\w+` | CWE-200 |
| R2.5 | 内部 API 端点 | `/api/v\d+/internal`、`/admin/`、`/debug/`、`/_debug` | CWE-200 |
| R2.6 | Swagger/OpenAPI | `swagger\.json`、`openapi\.json`、`/api-docs` | CWE-200 |
| R2.7 | 健康检查端点 | `/health`、`/healthz`、`/ready`、`/readiness`、`/liveness` | CWE-200 |
| R2.8 | 内部端口暴露 | `0\.0\.0\.0:\d{2,5}` | CWE-200 |

### R3 — 个人信息（高危 / High）

GDPR Article 5, 中国个人信息保护法

| ID | 检测项 | 模式 | 合规映射 |
|----|--------|------|----------|
| R3.1 | 手机号 | `1[3-9]\d{9}` | GDPR Art.5, 个保法 |
| R3.2 | 身份证号 | `[1-9]\d{5}(19\|20)\d{2}(0[1-9]\|1[0-2])(0[1-9]\|[12]\d\|3[01])\d{3}[\dXx]` | GDPR Art.5, 个保法 |
| R3.3 | 邮箱 | `[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}` | GDPR Art.5 |
| R3.4 | 银行卡号 | `[3-6]\d{15,18}` | PCI DSS |
| R3.5 | 护照号 | `[EeGg]\d{8}`、`[A-Z]\d{8}` (需结合上下文) | GDPR Art.5 |
| R3.6 | 姓名+身份证组合 | 包含 `姓名` 和 `身份证` 的同一行或相邻行 | GDPR Art.5, 个保法 |
| R3.7 | GPS 坐标 | `[-+]?([1-8]?\d(\.\d+)?\|90(\.0+)?),\s*[-+]?(180(\.0+)?\|((1[0-7]\d)\|([1-9]?\d))(\.\d+)?)` | GDPR Art.5 |
| R3.8 | MAC 地址 | `([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}` | GDPR Art.5 |

### R4 — 配置与环境（中危 / Medium）

CWE-215: Information Exposure Through Debug Information

| ID | 检测项 | 模式 | 合规映射 |
|----|--------|------|----------|
| R4.1 | 环境变量赋值 | `\$\w*env\w*:\s*\w+\s*=\s*["']sk-`、`export\s+\w*KEY\w*=` | CWE-215 |
| R4.2 | .env 引用 | `.env` 文件中定义的 key 出现在非 .env 文件中 | CWE-215 |
| R4.3 | 调试代码 | `console\.log.*password`、`console\.log.*token`、`debugger`、`breakpoint` | CWE-215 |
| R4.4 | TODO/FIXME with Security | `TODO.*security`、`FIXME.*auth`、`HACK.*password` | CWE-215 |
| R4.5 | 测试用硬编码 | `test.*password.*=`、`mock.*token.*=` | CWE-215 |
| R4.6 | 详细错误信息 | `stacktrace`、`stack_trace`、`err\.stack` | CWE-215 |
| R4.7 | 日志中的敏感信息 | `log\.\w+\(.*password`、`logger\.\w+\(.*secret` | CWE-215 |
| R4.8 | CORS 配置 | `Access-Control-Allow-Origin.*\*`、`cors\(.*origin.*\*` | CWE-942 |
| R4.9 | 不安全的 HTTP | `http://` (非 localhost/127.0.0.1) | CWE-319 |

### R5 — 文件权限与结构（中危 / Medium）

CWE-732: Incorrect Permission Assignment for Critical Resource

| ID | 检测项 | 说明 | 合规映射 |
|----|--------|------|----------|
| R5.1 | .gitignore 缺失 | 项目根目录无 `.gitignore` | CWE-732 |
| R5.2 | 敏感文件存在 | 检查是否存在 `.env`、`credentials.json`、`*.pem`、`*.key`、`*.p12`、`*.pfx`、`*.jks` | CWE-732 |
| R5.3 | 过大文件 | 单文件 > 1MB（可能意外包含二进制或数据转储） | CWE-732 |
| R5.4 | 可执行文件 | `*.exe`、`*.dll`、`*.so`、`*.dylib`、`*.bat`、`*.cmd`、`*.ps1`、`*.sh` | CWE-732 |
| R5.5 | 配置文件权限 | `.env`、`config.*`、`settings.*` 是否在版本控制中 | CWE-732 |
| R5.6 | 依赖锁文件 | 检查 `package-lock.json`、`yarn.lock`、`Pipfile.lock` 是否存在 | CWE-732 |
| R5.7 | Docker 配置 | `Dockerfile`、`docker-compose.yml` 中的安全配置 | CWE-732 |

### R6 — 代码安全（高危 / High）

OWASP Top 10 2021

| ID | 检测项 | 模式 | 合规映射 |
|----|--------|------|----------|
| R6.1 | SQL 注入风险 | `query\(.*\+`、`execute\(.*\+`、`SELECT.*\$\{`、`SELECT.*\+.*WHERE` | CWE-89, OWASP A03 |
| R6.2 | XSS 风险 | `innerHTML\s*=`、`outerHTML\s*=`、`document\.write\(`、`eval\(` | CWE-79, OWASP A03 |
| R6.3 | 命令注入风险 | `exec\(`、`spawn\(`、`system\(`、`popen\(` (需检查参数是否可控) | CWE-78, OWASP A03 |
| R6.4 | 路径遍历风险 | `\.\./`、`\.\.\\`、`path\.join\(.*\.\.` | CWE-22, OWASP A01 |
| R6.5 | 不安全的反序列化 | `pickle\.load`、`yaml\.load\(`、`deserialize\(` | CWE-502, OWASP A08 |
| R6.6 | 弱加密算法 | `MD5`、`SHA1`、`DES`、`RC4`、`ECB` | CWE-327 |
| R6.7 | 不安全的随机数 | `Math\.random\(`、`random\.random\(` | CWE-330 |
| R6.8 | SSRF 风险 | `requests\.get\(.*user`、`fetch\(.*param` | CWE-918, OWASP A10 |
| R6.9 | 文件上传风险 | `multer`、`multipart`、`file_upload` (无限制) | CWE-434, OWASP A04 |
| R6.10 | 硬编码 IV/Salt | `iv\s*=\s*["'][^"']+["']`、`salt\s*=\s*["'][^"']+["']` | CWE-798 |

### R7 — 依赖安全（中危 / Medium）

OWASP A06: Vulnerable and Outdated Components

| ID | 检测项 | 说明 | 合规映射 |
|----|--------|------|----------|
| R7.1 | 过时依赖 | 检查 `package.json`、`requirements.txt`、`Gemfile`、`pom.xml` 中的版本 | OWASP A06 |
| R7.2 | 已知漏洞依赖 | 对比 CVE 数据库（需外部数据源） | OWASP A06 |
| R7.3 | 未锁定版本 | 依赖版本使用 `*`、`latest`、`>=` | OWASP A06 |
| R7.4 | 私有源配置 | `.npmrc`、`pip.conf`、`settings.xml` 中的私有仓库地址 | OWASP A06 |

### R8 — 合规性检查（中危 / Medium）

| ID | 检测项 | 说明 | 合规映射 |
|----|--------|------|----------|
| R8.1 | 隐私政策缺失 | 检查是否有 `privacy-policy`、`隐私政策` 相关文件 | GDPR Art.13, 个保法 |
| R8.2 | 用户协议缺失 | 检查是否有 `terms-of-service`、`用户协议` 相关文件 | GDPR Art.13 |
| R8.3 | 数据保留策略 | 检查是否有数据保留/删除相关配置 | GDPR Art.17 |
| R8.4 | 审计日志 | 检查是否有审计日志记录机制 | 等保 2.0 |
| R8.5 | 访问控制 | 检查是否有 RBAC/ACL 相关实现 | OWASP A01 |

---

## 执行流程

```
[1] 确定扫描范围
     ↓
[2] 初始化扫描环境
     ├── 加载规则集 R1-R8
     ├── 加载误报排除规则
     └── 初始化报告生成器
     ↓
[3] 并行扫描阶段
     ├── Phase 1: 高危规则扫描 (R1, R6)
     │   └── 逐一运行 Grep，每个模式单独搜索
     ├── Phase 2: 中危规则扫描 (R2, R3, R4, R7, R8)
     │   └── 批量 Grep 调用
     └── Phase 3: 低危规则扫描 (R5)
         └── Glob + Bash 检查
     ↓
[4] 结果验证阶段
     ├── 对每个命中项进行上下文确认
     ├── 排除误报（示例、注释、占位符）
     └── 脱敏处理
     ↓
[5] 风险评分
     ├── 计算 CVSS 基础分
     ├── 考虑环境因素
     └── 生成风险等级
     ↓
[6] 生成报告
     ├── 汇总发现
     ├── 详细分析
     ├── 修复建议
     └── 合规映射
```

### 扫描策略优化

#### 并行扫描

对于大型项目，采用并行扫描策略：

```
文件列表 → 分片（每片 100 文件）→ 并行扫描 → 合并结果
```

#### 增量扫描

支持增量扫描模式（需配合 Git）：

```bash
# 只扫描上次审计后变更的文件
git diff --name-only <last-audit-commit> HEAD
```

#### 智能采样

对于超大项目（>10000 文件），采用智能采样：

1. 优先扫描高风险目录（`src/`、`config/`、`api/`）
2. 优先扫描最近修改的文件
3. 随机采样低风险目录

---

## 脱敏规则

报告中对匹配内容做部分遮蔽：

| 数据类型 | 脱敏规则 | 示例 |
|----------|----------|------|
| API Key / Token | 保留前 4 位 + 后 4 位，中间用 `****` 替代 | `sk-abc123456789xyz` → `sk-a****789xyz` |
| 密码 | 完全遮蔽为 `****` | `mypassword123` → `****` |
| 手机号 | 保留前 3 位 + 后 4 位 | `13812345678` → `138****5678` |
| 身份证号 | 保留前 4 位 + 后 4 位 | `110101199001011234` → `1101****1234` |
| 邮箱 | 用户名保留前 2 字符 + `***` | `test@example.com` → `te***@example.com` |
| 银行卡号 | 保留前 4 位 + 后 4 位 | `6222021234567890` → `6222****7890` |
| IP 地址 | 保留前 2 段 | `192.168.1.100` → `192.168.***.***` |
| JWT Token | 保留 header 部分 | `eyJhbG...` → `eyJhbG...[REDACTED]` |
| 私钥 | 完全遮蔽 | `[PRIVATE KEY HEADER]` → `-----REDACTED-----` |

---

## 风险评分

### CVSS v3.1 基础分计算

采用 CVSS v3.1 评分框架，根据以下维度计算风险分数：

| 维度 | 值 | 说明 |
|------|-----|------|
| Attack Vector (AV) | N/A/L/P | 网络/相邻/本地/物理 |
| Attack Complexity (AC) | L/H | 低/高 |
| Privileges Required (PR) | N/L/H | 无/低/高 |
| User Interaction (UI) | N/R | 无/需要 |
| Scope (S) | U/C | 不变/改变 |
| Confidentiality (C) | N/L/H | 无/低/高 |
| Integrity (I) | N/L/H | 无/低/高 |
| Availability (A) | N/L/H | 无/低/高 |

### 风险等级映射

| CVSS 分数 | 风险等级 | 标记 | 响应时间 |
|-----------|----------|------|----------|
| 9.0 - 10.0 | 严重 (Critical) | 🔴 | 立即修复 |
| 7.0 - 8.9 | 高危 (High) | 🟠 | 24 小时内 |
| 4.0 - 6.9 | 中危 (Medium) | 🟡 | 1 周内 |
| 0.1 - 3.9 | 低危 (Low) | 🟢 | 1 月内 |
| 0.0 | 信息 (Info) | ℹ️ | 下次迭代 |

### 默认风险评分

| 规则 ID | 默认 CVSS | 风险等级 |
|---------|-----------|----------|
| R1 (硬编码凭据) | 7.5 | 🟠 高危 |
| R2 (内部 URL) | 5.3 | 🟡 中危 |
| R3 (个人信息) | 7.5 | 🟠 高危 |
| R4 (配置环境) | 3.7 | 🟢 低危 |
| R5 (文件权限) | 3.7 | 🟢 低危 |
| R6 (代码安全) | 8.1 | 🟠 高危 |
| R7 (依赖安全) | 5.3 | 🟡 中危 |
| R8 (合规性) | 5.3 | 🟡 中危 |

---

## 报告格式

输出为 Markdown 格式，包含以下部分：

```markdown
# 安全审计报告

**报告编号**: SA-YYYYMMDD-XXXX
**扫描时间**: YYYY-MM-DD HH:MM:SS
**扫描范围**: <目录/文件类型>
**扫描文件数**: N
**扫描耗时**: Xs
**审计工具**: security-audit v2.0.0
**合规标准**: OWASP Top 10 2021, CWE/SANS Top 25, GDPR, 等保 2.0

---

## 风险概览

| 风险等级 | 数量 | 占比 |
|----------|------|------|
| 🔴 严重 (Critical) | X | X% |
| 🟠 高危 (High) | X | X% |
| 🟡 中危 (Medium) | X | X% |
| 🟢 低危 (Low) | X | X% |
| ℹ️ 信息 (Info) | X | X% |

**总体风险评分**: X.X / 10.0
**风险等级**: 🟡 中危

---

## 发现汇总

| # | 风险等级 | 规则 ID | CWE | 文件 | 行号 | 匹配内容（脱敏） | CVSS |
|---|----------|---------|-----|------|------|------------------|------|
| 1 | 🔴 严重 | R1.1 | CWE-798 | src/config.js | 42 | sk-ab****xyz | 7.5 |
| 2 | 🟠 高危 | R6.2 | CWE-79 | src/utils.js | 15 | innerHTML = ... | 8.1 |

---

## 详细发现

### 1. 🔴 R1.1 — 硬编码 API Key

- **规则**: R1.1 — 硬编码凭据
- **CWE**: CWE-798: Use of Hard-coded Credentials
- **OWASP**: A07:2021 - Identification and Authentication Failures
- **CVSS**: 7.5 (High)
- **文件**: `src/config.js:42`
- **匹配**: `sk-ab****xyz`
- **上下文**:
  ```javascript
  const API_KEY = 'sk-abc123456789xyz'; // 硬编码的 API 密钥
  ```
- **风险说明**: 硬编码的 API 密钥可能被恶意用户获取，导致未授权访问。
- **修复建议**:
  1. 将密钥移至环境变量：`process.env.API_KEY`
  2. 使用 `.env` 文件管理敏感配置
  3. 确保 `.env` 文件已添加至 `.gitignore`
  4. 考虑使用密钥管理服务（AWS Secrets Manager, HashiCorp Vault）
- **修复优先级**: P1 (24 小时内)
- **修复难度**: 低

### 2. 🟠 R6.2 — XSS 风险

- **规则**: R6.2 — 代码安全
- **CWE**: CWE-79: Cross-site Scripting (XSS)
- **OWASP**: A03:2021 - Injection
- **CVSS**: 8.1 (High)
- **文件**: `src/utils.js:15`
- **匹配**: `innerHTML = ...`
- **上下文**:
  ```javascript
  element.innerHTML = userInput; // 未转义的用户输入
  ```
- **风险说明**: 直接将用户输入设置为 innerHTML 可能导致 XSS 攻击。
- **修复建议**:
  1. 使用 `textContent` 替代 `innerHTML`
  2. 或使用 DOMPurify 等库进行消毒：`DOMPurify.sanitize(userInput)`
  3. 实施内容安全策略 (CSP)
- **修复优先级**: P1 (24 小时内)
- **修复难度**: 低

---

## 合规映射

### OWASP Top 10 2021

| OWASP 分类 | 涉及发现 | 状态 |
|------------|----------|------|
| A01:2021 - Broken Access Control | R8.5 | ⚠️ 待检查 |
| A02:2021 - Cryptographic Failures | R6.6 | ✅ 通过 |
| A03:2021 - Injection | R6.1, R6.2, R6.3 | ❌ 发现问题 |
| A04:2021 - Insecure Design | - | ✅ 通过 |
| A05:2021 - Security Misconfiguration | R4, R5 | ⚠️ 待检查 |
| A06:2021 - Vulnerable Components | R7 | ⚠️ 待检查 |
| A07:2021 - Auth Failures | R1 | ❌ 发现问题 |
| A08:2021 - Software Integrity | R6.5 | ✅ 通过 |
| A09:2021 - Logging Failures | R4.7 | ⚠️ 待检查 |
| A10:2021 - SSRF | R6.8 | ✅ 通过 |

### CWE/SANS Top 25

| CWE ID | 涉及发现 | 状态 |
|--------|----------|------|
| CWE-79: XSS | R6.2 | ❌ 发现问题 |
| CWE-89: SQL Injection | R6.1 | ⚠️ 待检查 |
| CWE-798: Hard-coded Credentials | R1 | ❌ 发现问题 |
| CWE-200: Information Exposure | R2 | ⚠️ 待检查 |
| ... | ... | ... |

### GDPR 合规

| GDPR 条款 | 涉及发现 | 状态 |
|-----------|----------|------|
| Art.5 - 数据处理原则 | R3 | ⚠️ 待检查 |
| Art.13 - 信息提供 | R8.1, R8.2 | ⚠️ 待检查 |
| Art.17 - 删除权 | R8.3 | ⚠️ 待检查 |
| Art.32 - 处理安全 | R1, R6 | ❌ 发现问题 |

### 等保 2.0 合规

| 等保要求 | 涉及发现 | 状态 |
|----------|----------|------|
| 身份鉴别 | R1 | ❌ 发现问题 |
| 访问控制 | R8.5 | ⚠️ 待检查 |
| 安全审计 | R8.4 | ⚠️ 待检查 |
| 入侵防范 | R6 | ❌ 发现问题 |
| 数据完整性 | R6.6 | ✅ 通过 |
| 数据保密性 | R1, R3 | ❌ 发现问题 |

---

## 安全建议

### 紧急修复 (P0/P1)

1. **立即移除硬编码凭据**
   - 将所有硬编码的密钥、密码移至环境变量
   - 使用密钥管理服务（AWS Secrets Manager, HashiCorp Vault, 阿里云 KMS）
   - 轮换已泄露的密钥

2. **修复 XSS 漏洞**
   - 对所有用户输入进行转义处理
   - 使用安全的 DOM 操作方法
   - 实施内容安全策略 (CSP)

### 短期改进 (P2)

3. **加强输入验证**
   - 实施服务端输入验证
   - 使用参数化查询防止 SQL 注入
   - 实施文件上传限制

4. **完善安全配置**
   - 配置 CORS 白名单
   - 启用 HTTPS
   - 配置安全响应头

### 长期规划 (P3)

5. **建立安全开发生命周期 (SDL)**
   - 代码审查清单
   - 安全测试自动化
   - 定期安全培训

6. **合规性建设**
   - 完善隐私政策
   - 建立数据保留策略
   - 实施审计日志

---

## 未发现问题的规则

以下规则未触发，表示该维度当前无风险：

- R1.4 私钥
- R1.5 AWS 凭据
- ...

---

## 附录

### A. 扫描配置

```yaml
scan_config:
  version: "2.0.0"
  rules_enabled: [R1, R2, R3, R4, R5, R6, R7, R8]
  excluded_dirs: [node_modules, .git, dist, build]
  excluded_patterns: ["*.min.js", "*.map"]
  max_file_size: "10MB"
  timeout_per_file: "5s"
  parallel_workers: 4
```

### B. 工具版本

| 工具 | 版本 | 用途 |
|------|------|------|
| Grep | - | 正则模式搜索 |
| Glob | - | 文件模式匹配 |
| Read | - | 文件内容读取 |
| Bash | - | 系统命令执行 |

### C. 参考资源

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [CVSS v3.1 Calculator](https://www.first.org/cvss/calculator/3.1)
- [GDPR 文本](https://gdpr-info.eu/)
- [等保 2.0 标准](http://www.cac.gov.cn/)

---

## 工具使用

执行扫描时使用以下工具：

1. **Grep** — 对目标文件按正则模式搜索，是主要扫描手段
2. **Glob** — 确定扫描范围，列举目标文件
3. **Read** — 对 Grep 命中的上下文进行二次确认，排除误报
4. **Bash** — 检查文件大小（R5.3）、.gitignore 存在性（R5.1）、依赖版本（R7）

### 扫描策略

- 对 R1（严重）规则：逐一运行 Grep，每个模式单独搜索
- 对 R6（高危）规则：逐一运行 Grep，每个模式单独搜索
- 对 R2-R5, R7-R8 规则：可合并为批量 Grep 调用
- 所有命中项需 Read 上下文确认，排除注释中的示例值和文档中的占位符

### 批量扫描优化

```bash
# 合并相似模式的 Grep 调用
# R2 规则合并为单次 Grep
pattern="(localhost:\d{2,5}|127\.0\.0\.1:\d{2,5}|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+)"
```

---

## 误报排除

以下情况不计入发现：

### 文档与示例

- README / 文档中作为**示例**出现的占位符 key（如 `sk-你的key`、`sk-xxx`、`your-api-key`）
- 注释中明确标注为示例的代码片段
- `data.json` 中的 `"schema_version": "1.0"` 等非敏感赋值
- `card-templates.json` 中的模板定义 URL（属于公开资源路径）
- 测试文件中的 mock 数据（需明确标注为测试）

### 开发环境

- `localhost` 和 `127.0.0.1` 在开发文档中的引用
- `0.0.0.0` 在 Docker/K8s 配置中的引用
- 开发环境配置中的示例值

### 已知安全模式

- 使用 `crypto.createHash('sha256')` 的 SHA256 哈希
- 使用 `crypto.randomBytes()` 生成的随机数
- 使用 `bcrypt` 或 `argon2` 的密码哈希

### 误报排除规则表

| 规则 ID | 排除条件 | 示例 |
|---------|----------|------|
| R1.1 | 包含 `example`、`test`、`mock`、`sample` | `sk-test123456789` |
| R1.3 | 值为 `password`、`123456`、`admin` 等常见弱密码 | `password=123456` (测试数据) |
| R2.2 | 在文档/README 中 | `运行在 localhost:3000` |
| R3.1 | 在测试数据/示例中 | `13800138000` (示例号码) |
| R3.3 | 在文档/示例中 | `test@example.com` |
| R6.7 | 在非安全上下文中 | `Math.random()` 用于动画 |

---

## 本项目特别关注

针对 `card-template` 项目的特殊检查：

### 前端安全

- `skills/` 目录下的配置文件可能包含 API 调用代码，重点检查是否有 key 硬编码
- 各卡片目录下的 `metadata.md` 中的 URL 是否包含内部地址
- `.claude/settings.local.json` 等配置文件是否被意外提交
- `assets/` 目录下的文件名是否包含敏感信息

### 后端安全

- `services/english-scoring/` 目录下的 Python 服务是否有安全配置
- `requirements.txt` 中的依赖版本是否安全
- API 端点是否有认证和授权

### 配置安全

- `.gitignore` 是否包含所有敏感文件
- 环境变量管理是否规范
- Docker 配置是否安全

### 数据安全

- 用户数据是否加密存储
- 日志中是否包含敏感信息
- 数据传输是否使用 HTTPS

---

## 自动化集成

本审计工具通过 **AI DevSecOps Pipeline** ([skill-security-scan.yml](../../.github/workflows/skill-security-scan.yml)) 自动运行，详见 [skill-security-policy.md](skill-security-policy.md) §2。

### 管道中的角色

本审计工具的检测规则 R1-R8 由 `ci-scan.sh` 实现，在管道的 `sast-analysis` Job 中与 Semgrep 并行执行：

```
AI DevSecOps Pipeline
├── 🔑 Secrets Scan        (TruffleHog — 覆盖 R1 硬编码凭据)
├── 💉 Prompt Injection    (Prompt Audit — 专用注入检测)
├── 🛑 Execution Sandbox   (Bandit + ShellCheck — 覆盖 R6 代码安全)
├── 🐛 SAST Analysis       (Semgrep + ci-scan.sh — 覆盖 R1-R8 全规则)  ← 本 Skill
├── 🧠 CodeQL Analysis     (语义级深度分析)
└── 🚨 Failure Report      (聚合 PR 通知)
```

### 各 Job 与本审计规则的对应关系

| 管道 Job | 工具 | 覆盖的审计规则 |
|----------|------|---------------|
| `secrets-audit` | TruffleHog | R1.1-R1.18 (凭据), R3 (PII) |
| `prompt-security` | Python 自研脚本 | 提示词注入（本项目特有） |
| `execution-gate` | Bandit + ShellCheck | R6.3 (命令注入), R6.1 (注入风险) |
| `sast-analysis` | Semgrep + ci-scan.sh | R1-R8 全规则集 |
| `codeql-analysis` | CodeQL | R6.1-R6.10 (代码安全深度分析) |

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit (由 scripts/security/pre-commit-hook.sh 调用)

echo "Running security audit..."
bash scripts/security/ci-scan.sh --scope skills --scope .claude/skills --fail-on-high

if [ $? -ne 0 ]; then
    echo "❌ Security audit failed. Please fix issues before committing."
    exit 1
fi

echo "✅ Security audit passed."
```

### 管道触发条件

| 事件 | 条件 |
|------|------|
| Push | `main`/`master`/`byl-v1.0.0` + 命中 `skills/**`、`.claude/skills/**`、`cards/**`、`scripts/**` |
| Pull Request | 同上分支 & 路径 |
| Schedule | 每周四 21:31 (UTC+8) 全量扫描 |
| Manual | `workflow_dispatch` |

### 失败处理

- **独立重试**: 管道每个 Job 可单独 `Re-run failed jobs`
- **报告留存**: 审计报告作为 Artifact 保留 14 天
- **聚合通知**: 仅 PR 事件触发，所有失败 Job 合并为**一条** PR 评论，避免刷屏

---

## 历史对比

支持与上次审计结果对比，生成差异报告：

```markdown
## 历史对比

**上次审计**: 2026-07-09 21:31:00
**本次审计**: 2026-07-16 21:31:00

| 指标 | 上次 | 本次 | 变化 |
|------|------|------|------|
| 总发现数 | 15 | 12 | ↓ -3 |
| 严重 | 2 | 0 | ↓ -2 |
| 高危 | 5 | 3 | ↓ -2 |
| 中危 | 6 | 7 | ↑ +1 |
| 低危 | 2 | 2 | - |

### 新增发现

- 🟡 R4.9 — src/api.js:25 — 不安全的 HTTP 请求

### 已修复发现

- ✅ R1.1 — src/config.js:42 — 硬编码 API Key
- ✅ R6.2 — src/utils.js:15 — XSS 风险
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.1.0 | 2026-07-16 | 自动化集成更新：迁移至 AI DevSecOps Pipeline 单文件多并行架构；管道 Job 与审计规则对应关系；更新触发条件与失败处理 |
| 2.0.0 | 2024-01-22 | 企业级重构：增加 R6-R8 规则、CVSS 评分、合规映射、自动化集成 |
| 1.0.0 | 2024-01-01 | 初始版本：R1-R5 基础规则 |

---

**维护者**: 炎图科技
**最后更新**: 2026-07-16
**下次审查**: 2026-10-16

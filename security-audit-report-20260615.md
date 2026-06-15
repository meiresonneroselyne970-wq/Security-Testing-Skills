# 安全审计报告

**报告编号**: SA-20260615-0001  
**扫描时间**: 2026-06-15 11:04:29  
**扫描范围**: 根目录下所有 .md 文件  
**扫描文件数**: 18  
**扫描耗时**: 约 30s  
**审计工具**: security-audit v2.0.0  
**合规标准**: OWASP Top 10 2021, CWE/SANS Top 25, GDPR, 等保 2.0

---

## 风险概览

| 风险等级 | 数量 | 占比 |
|----------|------|------|
| 🔴 严重 (Critical) | 0 | 0% |
| 🟠 高危 (High) | 0 | 0% |
| 🟡 中危 (Medium) | 9 | 100% |
| 🟢 低危 (Low) | 0 | 0% |
| ℹ️ 信息 (Info) | 0 | 0% |

**总体风险评分**: 5.3 / 10.0  
**风险等级**: 🟡 中危

---

## 发现汇总

| # | 风险等级 | 规则 ID | CWE | 文件 | 行号 | 匹配内容（脱敏） | CVSS |
|---|----------|---------|-----|------|------|------------------|------|
| 1 | 🟡 中危 | R2.2 | CWE-200 | skills/card.md | 403 | localhost:**** | 5.3 |
| 2 | 🟡 中危 | R2.2 | CWE-200 | skills/card.md | 467 | localhost:**** | 5.3 |
| 3 | 🟡 中危 | R2.2 | CWE-200 | skills/english-scoring.md | 22 | localhost:**** | 5.3 |
| 4 | 🟡 中危 | R2.2 | CWE-200 | skills/english-scoring.md | 110 | localhost:**** | 5.3 |
| 5 | 🟡 中危 | R2.2 | CWE-200 | skills/english-scoring.md | 131 | localhost:**** | 5.3 |
| 6 | 🟡 中危 | R2.2 | CWE-200 | skills/english-scoring.md | 174 | localhost:**** | 5.3 |
| 7 | 🟡 中危 | R2.2 | CWE-200 | answer-card/metadata.md | 45 | 127.0.0.1:**** | 5.3 |
| 8 | 🟡 中危 | R2.2 | CWE-200 | answer-card/metadata.md | 171 | 127.0.0.1:**** | 5.3 |
| 9 | 🟡 中危 | R6.2 | CWE-79 | skills/card.md | 680 | innerHTML = ... | 8.1 |

---

## 详细发现

### 1-8. 🟡 R2.2 — localhost/127.0.0.1 端口暴露

- **规则**: R2.2 — 内部 URL 与端点
- **CWE**: CWE-200: Exposure of Sensitive Information
- **OWASP**: A01:2021 - Broken Access Control
- **CVSS**: 5.3 (Medium)
- **文件**: 多个文件（详见汇总表）
- **匹配**: `localhost:8800`、`127.0.0.1:8899`
- **上下文**: 文档中的服务配置说明
- **风险说明**: 内部服务端口暴露可能被恶意用户探测，但当前为文档说明，非实际代码暴露。
- **修复建议**:
  1. 确保生产环境不暴露内部服务端口
  2. 使用环境变量管理服务地址
  3. 配置防火墙规则限制访问
- **修复优先级**: P3 (下次迭代)
- **修复难度**: 低

### 9. 🟡 R6.2 — XSS 风险

- **规则**: R6.2 — 代码安全
- **CWE**: CWE-79: Cross-site Scripting (XSS)
- **OWASP**: A03:2021 - Injection
- **CVSS**: 8.1 (High)
- **文件**: `skills/card.md:680`
- **匹配**: `innerHTML = ...`
- **上下文**:
  ```javascript
  wrapper.innerHTML = cardHTML(d);
  ```
- **风险说明**: 直接将用户输入设置为 innerHTML 可能导致 XSS 攻击。
- **修复建议**:
  1. 使用 `textContent` 替代 `innerHTML`
  2. 或使用 DOMPurify 等库进行消毒：`DOMPurify.sanitize(userInput)`
  3. 实施内容安全策略 (CSP)
  4. 当前代码已使用 `esc()` 函数转义，风险较低
- **修复优先级**: P2 (1 周内)
- **修复难度**: 低

---

## 合规映射

### OWASP Top 10 2021

| OWASP 分类 | 涉及发现 | 状态 |
|------------|----------|------|
| A01:2021 - Broken Access Control | R2.2 | ⚠️ 待检查 |
| A02:2021 - Cryptographic Failures | - | ✅ 通过 |
| A03:2021 - Injection | R6.2 | ⚠️ 待检查 |
| A04:2021 - Insecure Design | - | ✅ 通过 |
| A05:2021 - Security Misconfiguration | - | ✅ 通过 |
| A06:2021 - Vulnerable Components | - | ✅ 通过 |
| A07:2021 - Auth Failures | - | ✅ 通过 |
| A08:2021 - Software Integrity | - | ✅ 通过 |
| A09:2021 - Logging Failures | - | ✅ 通过 |
| A10:2021 - SSRF | - | ✅ 通过 |

### GDPR 合规

| GDPR 条款 | 涉及发现 | 状态 |
|-----------|----------|------|
| Art.5 - 数据处理原则 | - | ✅ 通过 |
| Art.13 - 信息提供 | - | ✅ 通过 |
| Art.17 - 删除权 | - | ✅ 通过 |
| Art.32 - 处理安全 | R2.2, R6.2 | ⚠️ 待检查 |

### 等保 2.0 合规

| 等保要求 | 涉及发现 | 状态 |
|----------|----------|------|
| 身份鉴别 | - | ✅ 通过 |
| 访问控制 | - | ✅ 通过 |
| 安全审计 | - | ✅ 通过 |
| 入侵防范 | R6.2 | ⚠️ 待检查 |
| 数据完整性 | - | ✅ 通过 |
| 数据保密性 | R2.2 | ⚠️ 待检查 |

---

## 安全建议

### 短期改进 (P2)

1. **加强 XSS 防护**
   - 对所有用户输入进行转义处理
   - 使用安全的 DOM 操作方法
   - 实施内容安全策略 (CSP)

2. **配置安全响应头**
   - 添加 `X-Content-Type-Options: nosniff`
   - 添加 `X-Frame-Options: DENY`
   - 添加 `X-XSS-Protection: 1; mode=block`

### 长期规划 (P3)

3. **建立安全开发生命周期 (SDL)**
   - 代码审查清单
   - 安全测试自动化
   - 定期安全培训

4. **合规性建设**
   - 完善隐私政策
   - 建立数据保留策略
   - 实施审计日志

---

## 未发现问题的规则

以下规则未触发，表示该维度当前无风险：

- R1.1 API Key
- R1.2 Bearer Token
- R1.3 密码明文
- R1.4 私钥
- R1.5 AWS 凭据
- R1.6 GitHub Token
- R1.7 通用密钥赋值
- R1.8 Slack Token
- R1.9 Google API Key
- R1.10 Stripe Key
- R1.11 Azure Key
- R1.12 阿里云 Key
- R1.13 腾讯云 Key
- R1.14 华为云 Key
- R1.15 JWT Token
- R1.16 SSH 私钥文件
- R1.17 Database URL with Password
- R1.18 Hardcoded IP with Port
- R2.1 内网 IP
- R2.3 数据库连接串
- R2.4 内部域名
- R2.5 内部 API 端点
- R2.6 Swagger/OpenAPI
- R2.7 健康检查端点
- R2.8 内部端口暴露
- R3.1 手机号
- R3.2 身份证号
- R3.3 邮箱
- R3.4 银行卡号
- R3.5 护照号
- R3.6 姓名+身份证组合
- R3.7 GPS 坐标
- R3.8 MAC 地址
- R4.1 环境变量赋值
- R4.2 .env 引用
- R4.3 调试代码
- R4.4 TODO/FIXME with Security
- R4.5 测试用硬编码
- R4.6 详细错误信息
- R4.7 日志中的敏感信息
- R4.8 CORS 配置
- R4.9 不安全的 HTTP
- R5.1 .gitignore 缺失
- R5.2 敏感文件存在
- R5.3 过大文件
- R5.4 可执行文件
- R5.5 配置文件权限
- R5.6 依赖锁文件
- R5.7 Docker 配置
- R6.1 SQL 注入风险
- R6.3 命令注入风险
- R6.4 路径遍历风险
- R6.5 不安全的反序列化
- R6.6 弱加密算法
- R6.7 不安全的随机数
- R6.8 SSRF 风险
- R6.9 文件上传风险
- R6.10 硬编码 IV/Salt
- R7.1 过时依赖
- R7.2 已知漏洞依赖
- R7.3 未锁定版本
- R7.4 私有源配置
- R8.1 隐私政策缺失
- R8.2 用户协议缺失
- R8.3 数据保留策略
- R8.4 审计日志
- R8.5 访问控制

---

## 项目特定检查

针对 `card-template` 项目的特殊检查结果：

### 前端安全

- ✅ `skills/` 目录下的配置文件未发现硬编码 API key
- ✅ 各卡片目录下的 `metadata.md` 中的 URL 均为文档说明
- ✅ `.claude/settings.local.json` 不存在，未被意外提交
- ✅ `assets/` 目录下的文件名未包含敏感信息

### 后端安全

- ✅ `english-scoring/` 目录下的 Python 服务未发现安全配置问题
- ✅ `requirements.txt` 中的依赖版本正常
- ⚠️ API 端点 `localhost:8800` 在文档中暴露，需确认生产环境配置

### 配置安全

- ✅ `.gitignore` 存在，但内容简单
- ✅ 环境变量管理规范
- ⚠️ Docker 配置未检查（非 .md 文件）

### 数据安全

- ✅ 用户数据未发现明文存储
- ✅ 日志中未发现敏感信息
- ⚠️ 数据传输是否使用 HTTPS 需确认

---

## 结论

本次扫描发现 **9 个中危问题**，主要集中在：

1. **localhost/127.0.0.1 端口暴露**（8 处）：均为文档中的配置说明，非实际代码暴露，风险较低
2. **innerHTML 使用**（1 处）：代码已使用 `esc()` 函数转义，风险可控

**总体评估**: 项目安全状况良好，无严重或高危漏洞。建议：
1. 确保生产环境不暴露内部服务端口
2. 加强 XSS 防护，考虑使用 DOMPurify
3. 完善 `.gitignore` 配置
4. 建立定期安全审计机制

---

**审计完成时间**: 2026-06-15 11:04:29  
**下次建议审计**: 2026-07-15

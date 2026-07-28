---
name: test-suite-readme
description: Skill 安全扫描测试套件说明文档
---

# Skill 安全扫描 — 测试套件

本目录包含用于测试 **AI DevSecOps Pipeline** 的测试 Skill 和辅助脚本。

---

## 目录结构

```
skills/
├── README.md                    # 本文件
├── safe-skill.md                # 测试 1: 安全的 Skill（应通过全部扫描）
├── detection-test.md            # 测试 2: 威胁检测样本（应触发 T1-T6 告警）
├── sec-ignore-demo.md           # 测试 3: sec-ignore 内联豁免演示
└── test-helpers/
    ├── run-tests.sh             # 测试套件运行器（一键运行全部测试）
    ├── safe-calculator.py       # 安全的 Python 工具脚本（应通过 Bandit）
    └── safe-setup.sh            # 安全的 Bash 工具脚本（应通过 ShellCheck）
```

---

## 快速开始

### 运行全部测试

```bash
# 在项目根目录执行
bash skills/test-helpers/run-tests.sh
```

### 单独测试

```bash
# 测试 1: 扫描安全的 Skill
bash scripts/security/ci-scan.sh --scope skills/safe-skill.md --fail-on-high

# 测试 2: 检测威胁样本
bash scripts/security/ci-scan.sh --scope skills/detection-test.md --fail-on-high

# 测试 3: 验证 sec-ignore 豁免
bash scripts/security/ci-scan.sh --scope skills/sec-ignore-demo.md --fail-on-high

# 测试 4: 生成 JSON 报告
bash scripts/security/ci-scan.sh --scope skills --format json --output test-report.json
```

---

## 测试用例说明

| # | 测试 Skill | 测试目的 | 预期结果 |
|---|-----------|---------|---------|
| 1 | `safe-skill.md` | 验证合法 Skill 不会触发误报 | ✅ 0 个威胁告警，完全通过 |
| 2 | `detection-test.md` | 验证扫描器能检测 T1-T6 各类威胁 | ❌ 触发 20+ 条告警（Critical + High + Medium） |
| 3 | `sec-ignore-demo.md` | 验证 `<!-- sec-ignore -->` 内联豁免 | ✅ 仅未豁免的 1 行触发告警，其余豁免 |
| 4 | `safe-calculator.py` | 验证安全 Python 脚本通过 Bandit | ✅ 无 Bandit/ShellCheck 告警 |
| 5 | `safe-setup.sh` | 验证安全 Bash 脚本通过 ShellCheck | ✅ 无 ShellCheck 告警 |

---

## 覆盖的威胁类别

| 威胁类别 | detection-test.md | sec-ignore-demo.md |
|----------|:--:|:--:|
| **T1.1** 系统命令执行 | ✅ | — |
| **T1.2** 文件系统破坏 | ✅ | ✅ (豁免 + 未豁免) |
| **T1.3** 数据外传 | ✅ | — |
| **T1.4** 反向 Shell | ✅ | — |
| **T1.5** 权限提升 | ✅ | ✅ (豁免 + 未豁免) |
| **T1.7** 代码混淆 | ✅ | — |
| **T2.2** 提示词越狱 | ✅ | — |
| **T2.3** 注释中隐藏命令 | ✅ | — |
| **T3.1** 硬编码 API Key | ✅ | ✅ (豁免) |
| **T3.2** 硬编码 Token | ✅ | — |
| **T3.3** 硬编码密码 | ✅ | ✅ (豁免) |
| **T3.4** 私钥泄露 | ✅ | — |
| **T5.1** 凭据诱导 | ✅ | ✅ (豁免) |
| **T5.2** 紧急诱导 | ✅ | — |
| **T5.4** 安全绕过诱导 | ✅ | — |
| **T6.1** 外部脚本引用 | ✅ | — |
| **T6.2** 非白名单 CDN | ✅ | — |

---

## 与 CI 管道的关系

本测试套件中的文件与 CI 管道的关系：

| 文件 | CI 行为 | 说明 |
|------|---------|------|
| `safe-skill.md` | ✅ 通过 | 合法文件，不应阻塞 CI |
| `detection-test.md` | ❌ 失败 | 含威胁模式，会导致 `sast-analysis` Job 失败 |
| `sec-ignore-demo.md` | ⚠️ 不通过 | 有 1 个未豁免的 T1.5 威胁 |
| `test-helpers/*.py` | ✅ 通过 | 安全脚本，通过 Bandit 扫描 |
| `test-helpers/*.sh` | ✅ 通过 | 安全脚本，通过 ShellCheck 扫描 |

> ⚠️ **注意**: `detection-test.md` 包含故意放置的威胁模拟样本，会导致 CI 管道失败。
> 如果需要在 CI 中排除此文件，请将其添加到 `.security-whitelist.yml` 的 `file_whitelist` 中。

---

## 自定义测试

如需添加自定义测试 Skill，请参照现有文件的格式：

1. 创建新的 `.md` 文件，包含 YAML frontmatter（`name` + `description`）
2. 在文件中添加要测试的威胁模式
3. 运行 `run-tests.sh` 验证

---

**维护者**: 测试团队
**创建日期**: 2026-07-28

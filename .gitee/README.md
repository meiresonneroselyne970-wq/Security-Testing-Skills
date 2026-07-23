# Gitee CI/CD 流水线配置

本目录存放 Gitee Go 平台的 CI/CD 流水线配置，与 `.github/workflows/` 并列维护。

## 目录结构

```
.gitee/
├── README.md                              # 本文件
├── scripts/
│   └── audit_prompts.py                   # 提示词注入审计脚本（独立可执行）
└── workflows/
    └── skill-security-scan.yml            # AI DevSecOps 管道（version 2.3.0-gitee）
```

## 两个入口文件

| 文件 | 用途 |
|------|------|
| `.gitee-ci.yml`（仓库根目录） | Gitee Go **自动检测**的入口，经典 GitLab CI 风格，兼容性最好 |
| `.gitee/workflows/skill-security-scan.yml` | **高级版**，`version: '1.0'` 格式，支持并行阶段、制品上传、PR 聚合通知 |

## 使用方式

### 方式 1：自动检测（推荐新项目）

直接推送代码，Gitee Go 会自动检测根目录的 `.gitee-ci.yml` 并触发流水线。

### 方式 2：手动指定高级版

1. Gitee 项目 → **流水线** → **新建流水线**
2. 选择 **代码视图** → 粘贴 `.gitee/workflows/skill-security-scan.yml` 内容
3. 或直接指向文件路径：`.gitee/workflows/skill-security-scan.yml`

## 流水线配置

### 触发条件

| 事件 | 条件 |
|------|------|
| Push | `main` / `master` / `byl-v1.0.0` 分支 + 扫描路径变更 |
| Pull Request | 同上分支 & 路径 |
| Schedule | 每周四 21:31 (UTC+8) |
| Manual | `workflow_dispatch` / 手动触发 |

### 安全门禁（6 个阶段）

```
AI DevSecOps Pipeline (Gitee)
├── 🔑 Secrets Scan        (TruffleHog 增量扫描)
├── 💉 Prompt Injection    (audit_prompts.py 注入检测)
├── 🛑 Execution Sandbox   (Bandit + ShellCheck + JS 系统调用)
├── 🐛 SAST Analysis       (Semgrep + ci-scan.sh T1-T7)
└── 🚨 Failure Report      (Gitee PR 聚合通知)
```

## 与 GitHub Actions 的差异

| 功能 | GitHub Actions | Gitee Go |
|------|---------------|----------|
| CodeQL 语义分析 | ✅ `github/codeql-action` | ❌ GitHub 专有，Gitee 不支持 |
| TruffleHog | ✅ | ✅ 原生安装 |
| Bandit | ✅ | ✅ pip install |
| ShellCheck | ✅ `ludeeus/action-shellcheck` | ✅ apt install |
| Semgrep | ✅ | ✅ pip install |
| PR 评论 | ✅ `actions/github-script` | ✅ Gitee API (需 `GITEE_TOKEN`) |
| 制品上传 | ✅ `actions/upload-artifact` | ✅ Gitee 原生制品管理 |
| 并行执行 | ✅ `needs` | ✅ `dependsOn` / 并行阶段 |

## 所需 Token 配置

在 Gitee 项目 → **流水线设置** → **安全变量** 中添加：

| 变量名 | 说明 | 是否必需 |
|--------|------|----------|
| `GITEE_TOKEN` | Gitee 个人访问令牌（用于 PR 评论 API） | 可选（无则跳过 PR 通知） |

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.3.0-gitee | 2026-07-23 | 从 GitHub Actions 迁移至 Gitee Go；移除 CodeQL；新增 audit_prompts.py 独立脚本；双入口文件设计 |

---

**维护者**: card-template Security Team
**最后更新**: 2026-07-23

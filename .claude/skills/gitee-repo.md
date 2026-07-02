# Skill: gitee-repo

Gitee（码云）仓库管理工具，支持克隆、拉取、更新 Gitee 仓库，支持 HTTPS/SSH 两种协议及多种认证方式。

**版本**: 1.0.0
**适用场景**: 拉取 Gitee 仓库代码、批量克隆项目、同步 Gitee 仓库、子模块管理

---

## Trigger

当用户提到以下任何一种情况时触发此 skill：

- 拉取 Gitee / 码云 仓库
- 克隆 Gitee / 码云 项目
- 下载 Gitee 代码
- 同步 Gitee 仓库
- clone gitee / pull gitee
- 更新 Gitee 仓库
- gitee.com 上的项目

---

## 核心能力

| 能力 | 说明 |
|------|------|
| 克隆仓库 | `git clone` 支持 HTTPS / SSH / Gitee CLI 三种协议 |
| 拉取更新 | `git pull` / `git fetch` 拉取最新代码 |
| 认证管理 | 支持用户名+密码、Personal Access Token、SSH Key |
| 批量操作 | 支持批量克隆/同步多个仓库 |
| 子模块处理 | 自动初始化和更新 Git 子模块 |
| 分支管理 | 支持指定分支/标签克隆 |
| 镜像克隆 | `git clone --mirror` 完整镜像 |

---

## 协议与认证

### 1. HTTPS 协议（推荐）

```
https://gitee.com/<owner>/<repo>.git
```

**认证方式**：

| 方式 | 说明 | 安全性 |
|------|------|--------|
| 用户名 + 密码 | Gitee 登录密码 | ⚠️ 低（已废弃） |
| 用户名 + Personal Access Token | 私人令牌替代密码 | ✅ 推荐 |
| URL 内嵌 Token | `https://oauth2:TOKEN@gitee.com/...` | ⚠️ 中等（会暴露在 URL 中） |
| Git Credential Manager | 系统凭据管理器自动处理 | ✅ 推荐 |

### 2. SSH 协议

```
git@gitee.com:<owner>/<repo>.git
```

**前置条件**：需在 Gitee 设置中[添加 SSH 公钥](https://gitee.com/profile/sshkeys)。

### 3. Gitee CLI（gwf）

```bash
# 安装
npm install -g @gitee/cli

# 使用
gwf clone <owner>/<repo>
```

---

## 操作指南

### 单仓库克隆

```bash
# HTTPS 克隆（默认分支）
git clone https://gitee.com/<owner>/<repo>.git

# HTTPS 克隆 + Token 认证
git clone https://<username>:<token>@gitee.com/<owner>/<repo>.git

# SSH 克隆
git clone git@gitee.com:<owner>/<repo>.git

# 指定分支克隆
git clone -b <branch> https://gitee.com/<owner>/<repo>.git

# 浅克隆（只克隆最近 N 次提交，加速大仓库）
git clone --depth 1 https://gitee.com/<owner>/<repo>.git

# 克隆到指定目录
git clone https://gitee.com/<owner>/<repo>.git <target-dir>

# 递归克隆（含子模块）
git clone --recurse-submodules https://gitee.com/<owner>/<repo>.git
```

### 仓库更新

```bash
# 拉取最新代码
git pull

# 仅获取远程变更（不合并）
git fetch origin

# 拉取并 rebase
git pull --rebase

# 同步所有子模块
git submodule update --init --recursive
```

### 批量操作

```bash
# 批量克隆多个仓库
repos=(
  "owner1/repo1"
  "owner2/repo2"
)

for repo in "${repos[@]}"; do
  git clone "https://gitee.com/${repo}.git"
done
```

---

## Personal Access Token 配置

### 1. 在 Gitee 生成 Token

1. 登录 Gitee → 设置 → [私人令牌](https://gitee.com/profile/personal_access_tokens)
2. 点击「生成新令牌」
3. 勾选权限：`projects`（仓库读写）、`user_info`（用户信息）
4. 复制生成的 Token（仅显示一次！）

### 2. 配置 Git 凭据

**方式一：Git Credential Manager（推荐）**

```bash
# 首次克隆时 Git 会提示填写用户名与令牌
git clone https://gitee.com/<owner>/<repo>.git
# Username 栏填: <你的Gitee用户名>
# Password 栏填: <Personal Access Token>

# 凭据会被系统自动保存
```

**方式二：Git 全局配置**

```bash
# 设置凭据缓存（默认 15 分钟）
git config --global credential.helper cache

# 设置凭据永久存储
git config --global credential.helper store

# 设置缓存超时（秒）
git config --global credential.helper 'cache --timeout=3600'
```

**方式三：URL 重写（Token 统一注入）**

```bash
# 配置后所有 gitee.com 请求自动携带 Token
git config --global url."https://<username>:<token>@gitee.com/".insteadOf "https://gitee.com/"
```

---

## 执行流程

```
[1] 解析用户意图
     ├── 单仓库 / 批量
     ├── HTTPS / SSH 协议选择
     └── 目标分支/标签
     ↓
[2] 检查前置条件
     ├── Git 是否安装
     ├── SSH Key 是否配置（SSH 模式）
     └── Token 是否可用（HTTPS 模式）
     ↓
[3] 执行操作
     ├── git clone（首次）
     ├── git pull / git fetch（已有仓库）
     └── git submodule update（子模块）
     ↓
[4] 验证结果
     ├── 检查克隆完整性
     ├── 检查分支是否正确
     └── 输出仓库信息
```

---

## 常用命令速查

### 克隆相关

| 场景 | 命令 |
|------|------|
| 快速克隆（仅最新提交） | `git clone --depth 1 <url>` |
| 指定分支 | `git clone -b <branch> <url>` |
| 含子模块 | `git clone --recurse-submodules <url>` |
| 镜像克隆 | `git clone --mirror <url>` |
| 不检出文件 | `git clone --bare <url>` |

### 更新相关

| 场景 | 命令 |
|------|------|
| 拉取当前分支 | `git pull` |
| 仅查看远程更新 | `git fetch --dry-run` |
| 拉取所有远程分支 | `git fetch --all` |
| 强制同步到远程 | `git reset --hard origin/<branch>` |
| 清理本地无用引用 | `git remote prune origin` |

### 信息查看

| 场景 | 命令 |
|------|------|
| 查看远程地址 | `git remote -v` |
| 查看远程分支 | `git branch -r` |
| 查看本地与远程差异 | `git log HEAD..origin/<branch>` |
| 查看仓库大小 | `du -sh .git` |

---

## 常见问题处理

### Q1: 克隆时提示 "fatal: Authentication failed"

```bash
# 确认 Token 有效，重新设置凭据
git config --global --unset credential.helper
git config --global credential.helper manager

# 或清除旧凭据后重试
# Windows: 凭据管理器 → Windows 凭据 → 删除 gitee.com 相关条目
# Mac: 钥匙串访问 → 搜索 gitee → 删除
```

### Q2: 大仓库克隆慢/失败

```bash
# 方案 1：浅克隆
git clone --depth 1 <url>

# 方案 2：逐步加深
git clone --depth 1 <url>
git fetch --depth=100
git fetch --unshallow  # 最终拉取完整历史

# 方案 3：仅克隆指定分支
git clone --single-branch -b <branch> <url>
```

### Q3: 子模块拉取失败

```bash
# 子模块 URL 可能使用了 SSH，检查 .gitmodules
cat .gitmodules

# 初始化并更新所有子模块
git submodule update --init --recursive

# 如果子模块 URL 不对，修改后同步
git submodule sync
git submodule update --init --recursive
```

### Q4: HTTPS 与 SSH 协议切换

```bash
# HTTPS → SSH
git remote set-url origin git@gitee.com:<owner>/<repo>.git

# SSH → HTTPS
git remote set-url origin https://gitee.com/<owner>/<repo>.git
```

---

## 安全注意事项

| 规则 | 说明 |
|------|------|
| 不硬编码 Token | Token 通过环境变量或凭据管理器传入，不写入脚本 |
| `.gitignore` 检查 | 克隆后检查 `.gitignore` 是否包含 `.env`、`*.key` |
| HTTPS 优先 | 企业内网无法使用 SSH 时，优先使用 HTTPS + Token |
| Token 最小权限 | Token 仅授予必要的仓库访问权限 |
| 定期轮换 Token | 建议每 90 天更换一次 Personal Access Token |
| 不提交凭据文件 | `.git-credentials` 等文件不要提交到仓库 |

---

## 工具使用

执行 Gitee 仓库操作时使用以下工具：

1. **Bash** — 执行 `git clone`、`git pull`、`git fetch` 等 Git 命令
2. **Glob** — 检查目标目录是否已存在仓库（`.git` 目录）
3. **Read** — 读取 `.gitmodules`、`.git/config` 等配置文件

### 执行原则

- 克隆前先检查目标目录是否已存在
- 若已存在同名目录，询问用户是覆盖、更新还是跳过
- 大仓库（>100MB）自动启用浅克隆（`--depth 1`）
- 操作完成后输出仓库名称、分支、最新提交信息

---

## 环境变量参考

```bash
# 推荐的环境变量命名
GITEE_USERNAME=<your-username>
GITEE_TOKEN=<your-personal-access-token>

# 使用示例
git clone https://${GITEE_USERNAME}:${GITEE_TOKEN}@gitee.com/<owner>/<repo>.git
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-07-02 | 初始版本：HTTPS/SSH 克隆、Token 认证、批量操作、常见问题 |

---

**维护者**: card-template team
**最后更新**: 2026-07-02

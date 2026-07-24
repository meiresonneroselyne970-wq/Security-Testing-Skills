---
name: gitee-repo
description: 管理 `https://gitee.com/blazegraph/card-template.git` 仓库。支持克隆、拉取、推送、分支切换。与 skill-manager 联动完成 skill 分发。
---

# gitee-repo — 拉取 card-template 仓库

**版本**: 1.2.0
**目标仓库**: `https://gitee.com/blazegraph/card-template.git`
**适用场景**: 克隆/拉取/同步 card-template 仓库

---

## Trigger

当用户提到以下任何一种情况时触发此 skill：

- 拉取 card-template 仓库
- 克隆 card-template 项目
- 同步/更新 card-template 代码
- 拉取 gitee 上的 card-template
- clone/pull card-template

---

## 操作指南

### 首次克隆

```bash
git clone https://gitee.com/blazegraph/card-template.git
```

### 已存在仓库时拉取更新

```bash
cd card-template
git pull
```

### 强制同步到远程（丢弃本地修改）

```bash
cd card-template
git fetch origin
git reset --hard origin/<branch>
```

### 查看远程分支

```bash
cd card-template
git branch -r
```

### 切换分支

```bash
cd card-template
git checkout <branch>
git pull
```

---

## 执行流程

```
[1] 检查目标目录是否已存在
     ├── 不存在 → git clone
     └── 已存在 → git pull
     ↓
[2] 执行操作
     ↓
[3] 验证结果
     ├── 显示当前分支
     ├── 显示最新提交信息
     └── 显示工作区状态
```

---

## 与 skill-manager 联动

本技能负责仓库的拉取/推送，[skill-manager](skill-manager.md) 负责 skill 的分析与打包。两者配合覆盖完整的 skill 分发流水线。

### 场景 A：拉取后刷新 skill 索引

从 Gitee 拉取最新代码后（可能包含新增/更新的 skill 文件），交由 skill-manager 重新分析：

```bash
# gitee-repo — 拉取
cd card-template
git pull

# skill-manager — 刷新索引
C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python .claude/skills/analyze-skills.py
```

### 场景 B：skill 打包后推送到 Gitee

skill-manager 生成分发包（`packages/*.zip` + `skills-index.json`）后，由本技能提交并推送：

```bash
# skill-manager 已完成打包 → packages/ 目录有 ZIP/JSON 文件
git add packages/ skills-index.json
git commit -m "release: skill 分发包"
git push origin <branch>
```

### 场景 C：完整发布流水线

```
skill-manager                    gitee-repo
    │                                │
    ├─ analyze-skills.py             │
    ├─ 按分类/全部 ZIP 打包           │
    │                                │
    └──────── 交接 ─────────────────→│
                                     ├─ git add packages/
                                     ├─ git commit
                                     └─ git push → Gitee
```

---

## 执行原则

- 克隆前先检查目标目录（`card-template`）是否已存在
- 若已存在，直接 `git pull` 拉取最新代码
- 操作完成后输出当前分支、最新提交信息、工作区状态
- 使用 `Bash` 工具执行 Git 命令

---

## 常见问题

### Q1: 克隆时提示 "fatal: Authentication failed"

```bash
# 确认凭据设置
git config --global credential.helper manager

# Windows: 凭据管理器 → Windows 凭据 → 删除 gitee.com 相关条目后重试
```

### Q2: 本地有修改导致 pull 失败

```bash
# 暂存本地修改
git stash
git pull
git stash pop  # 恢复本地修改
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-07-02 | 初始版本：通用 Gitee 仓库管理 |
| 1.1.0 | 2026-07-02 | 精简为专用于 `blazegraph/card-template` 仓库 |
| 1.2.0 | 2026-07-03 | 新增与 skill-manager 联动：拉取后刷新索引、打包后推送分发 |

---

**维护者**: card-template team
**最后更新**: 2026-07-02

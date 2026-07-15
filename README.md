# Card Template — AI 卡片模板库

可复用的 AI 卡片 UI 组件库，包含 8 种卡片模板，支持文本展示、作业提醒、媒体预览、英语学习、连环画、AI 问答等场景。每个卡片模板为独立的自包含组件（HTML + CSS + JS + JSON 数据），可直接通过 `<iframe>` 或自定义 `<ai-card>` 标签嵌入。

> 📋 完整卡片目录见 **[cards/](cards/)**（8 种卡片分文件记录）

---

## 目录结构

```
card-template/
├── cards/                 # 📋 卡片总目录（8 种卡片 + 英语评分服务）
│   ├── README.md          # 主索引
│   ├── text-card/         # 通用文本卡片（5 种变体）
│   ├── homework-card/     # 学科作业提醒卡片
│   ├── media-card/        # 媒体预览卡片（视频/音频/图片）
│   ├── english-word-card/ # 英语单词启蒙卡片
│   ├── comic-card/        # 连环画/漫画分页卡片（含 assets/ 图片+视频）
│   ├── answer-card/       # AI 问答卡片（独立架构，纯 HTML+CSS+JS）
│   ├── english-sentence-card/ # 英语句子展示卡片（每日一句）
│   ├── english-input-card/   # 英语句子输入卡片（可编辑）
│   └── services/
│       └── english-scoring/  # 英语口语 AI 评分服务（FastAPI + DeepSeek）
│
├── skills/               # 通用卡片生成技能（selector、card、card_render 等 5 个）
├── .claude/skills/       # 系统管理技能（安全审计、仓库管理等 6 个）
│
├── scripts/              # 工具脚本
│   └── security/         # 安全扫描脚本（PowerShell + Bash + Bat）
│
└── .gitattributes        # 强制 LF 行尾（跨平台兼容）
```

---

## 卡片模板一览

| 模板 | 目录 | 适用场景 |
|------|------|----------|
| **文本卡片** | `cards/text-card/` | 通用入口、AI 助手欢迎、推荐、任务提醒、健康建议 |
| **作业提醒** | `cards/homework-card/` | 语文/数学/英语学科作业提醒，彩色渐变横幅 |
| **媒体预览** | `cards/media-card/` | 视频/音频/图片/文件预览，暗色预览区 + 播放按钮 |
| **英语单词** | `cards/english-word-card/` | 字母/单词启蒙，笔记本横线纸 + 大字母 + 图片 + 发音 |
| **连环画** | `cards/comic-card/` | PEP 外研版英语连环画，视频播放 + 分页漫画气泡 |
| **AI 问答** | `cards/answer-card/` | AI 知识问答，DeepSeek API 集成，文件来源展示 |
| **英语句子展示** | `cards/english-sentence-card/` | 每日一句，缎带徽章 + 点击翻译 + TTS + 跟读评分 |
| **英语输入** | `cards/english-input-card/` | 自由输入句子，实时 API 翻译 + TTS + 跟读评分 |

每个卡片模板目录包含：
- `index.html` — 卡片主页面
- `ai-card.js`（或 `app.js`） — 卡片逻辑（数据加载、渲染、交互）
- `ai-card.css`（或 `style.css`） — 卡片样式（5 设备响应式适配）
- `*.json` — 静态数据（一个或多个，answer-card 无外部数据文件）
- `skill.md` — 技能文档（全部卡片）
- `assets/` — 静态资源（仅 comic-card，含 38 张图片 + 7 个视频）
- `fonts/` — 本地字体（仅英语系列 3 个卡片）

---

## 技能系统

项目有两套独立的技能系统，按归属分为三类：

### `skills/` — 通用卡片生成技能（5 个）

面向卡片生成业务的核心流水线：`selector` → `resource_lookup` → `card_render`

| 技能 | 文件 | 职责 |
|------|------|------|
| selector | `skills/selector.md` | 技能索引，路由查找/渲染 |
| resource_lookup | `skills/resource_lookup.md` | 跨目录搜索已有资源 |
| card_render | `skills/card_render.md` | 纯渲染引擎，templateId + data → HTML |
| card | `skills/card.md` | 卡片生成入口，决策复用/新建模板 |
| image-generator | `skills/image-generator.md` | AI 插图生成，替换 target_url |

### 卡片专属技能（已归入对应目录）

| 技能 | 位置 | 对应卡片/服务 |
|------|------|-------------|
| comic | `cards/comic-card/skill.md` | 连环画卡片生成 |
| english-scoring | `cards/services/english-scoring/skill.md` | 英语口语 AI 评分 |

### `.claude/skills/` — 系统管理技能（6 个）

| 技能 | 文件 | 职责 |
|------|------|------|
| 安全审计 | `.claude/skills/security-audit.md` | Skill 文件安全审计 |
| 安全策略 | `.claude/skills/skill-security-policy.md` | 安全策略定义 |
| 安全扫描器 | `.claude/skills/skill-security-scanner.md` | 自动安全扫描引擎 |
| 技能管理 | `.claude/skills/skill-manager.md` | 技能生命周期管理 |
| 仓库管理 | `.claude/skills/gitee-repo.md` | Gitee 仓库操作 |
| 技能分析 | `.claude/skills/analyze-skills.py` | 解析 skill 文件，输出 JSON |

---

## 英语评分服务

`cards/services/english-scoring/` 提供英语口语 AI 评分能力，调用 DeepSeek API 对跟读进行多维度评分（发音准确度、完整性、流利度、语调自然度等）。

```bash
cd cards/services/english-scoring/
pip install -r requirements.txt
python server.py
# → Uvicorn running on http://0.0.0.0:8800
```

支持 3 种评分模式：`english_word`、`english_sentence`、`english_input`

---

## 安全扫描

项目集成了 Skill 文件安全扫描，自动检测恶意代码注入、隐藏危险指令、敏感信息泄露等问题。

```bash
# 本地扫描
bash scripts/security/ci-scan.sh --scope skills --scope .claude/skills

# Windows
.\scripts\security\skill-security-scan.ps1 -Scope skills/
```

通过 Git pre-commit hook 在每次 commit 时自动触发扫描。安装方式：`cp scripts/security/pre-commit-hook.sh .git/hooks/pre-commit`

---

## 响应式适配

所有卡片支持 5 设备分段：

| 设备 | 断点 | 适用 |
|------|------|------|
| 手机 | < 480px | 竖屏手机 |
| 平板 | ≥ 480px | 平板竖屏 |
| 大屏 | ≥ 768px | 平板横屏 |
| 桌面 | ≥ 1024px | PC 浏览器 |
| 电视 | ≥ 1440px | 大屏展示 |

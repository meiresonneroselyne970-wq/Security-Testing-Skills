# 卡片模板目录

AI 卡片模板库完整目录，共 8 种卡片模板。每个模板为独立的自包含组件（HTML + CSS + JS + JSON 数据），支持 `<iframe>` 或 `<ai-card>` Web Component 嵌入。

---

## 概览

| # | 模板 | 目录 | 架构 | 适用场景 |
|---|------|------|------|----------|
| 1 | **文本卡片** | [text-card/](./text-card/) | Web Component | 通用入口、AI 助手欢迎、推荐、任务提醒、健康建议 |
| 2 | **作业提醒** | [homework-card/](./homework-card/) | Web Component | 语文/数学/英语学科作业提醒，彩色渐变横幅 |
| 3 | **媒体预览** | [media-card/](./media-card/) | Web Component | 视频/音频/图片/文件预览，暗色预览区 + 播放按钮 |
| 4 | **英语单词** | [english-word-card/](./english-word-card/) | Web Component | 字母/单词启蒙，笔记本横线纸 + 大字母 + 图片 + 发音 |
| 5 | **连环画** | [comic-card/](./comic-card/) | Web Component | PEP 外研版英语连环画，视频播放 + 分页漫画气泡 |
| 6 | **AI 问答** | [answer-card/](./answer-card/) | Standalone | AI 知识问答，DeepSeek API 集成，文件来源展示 |
| 7 | **英语句子展示**| [english-sentence-card/](./english-sentence-card/) | Web Component | 每日一句，缎带徽章 + 点击翻译 + TTS + 跟读评分 |
| 8 | **英语输入** | [english-input-card/](./english-input-card/) | Web Component | 自由输入句子，实时 API 翻译 + TTS + 跟读评分 |

> **英语评分服务**：[services/english-scoring/](./services/english-scoring/) — 为 english-word、english-sentence、english-input 三类卡片提供 DeepSeek API 多维度发音评分。对应技能：[services/english-scoring/skill.md](./services/english-scoring/skill.md)

---

## 架构分类

| 架构 | 模式 | 渲染方式 | 共享引擎 | 包含模板 |
|------|------|----------|----------|----------|
| **Web Component** | `<ai-card>` + Shadow DOM | `ai-card.js` 读取 `data` 属性 → 渲染到 Shadow DOM | `ai-card.css` 在 Shadow DOM 内 | text, homework, media, english-word, comic, english-sentence, english-input |
| **Standalone** | 纯 HTML + CSS + 原生 JS | `app.js` 直接操作 DOM | CSS 类在全局文档上 | answer |

---

## 1. 文本卡片 — [text-card/](./text-card/)

通用文本类卡片，覆盖 5 种 card_type。顶部渐变装饰条 + 左侧品牌色条 + 图标 + 标题 + 描述 + 按钮。

| 属性 | 值 |
|------|-----|
| **card_type** | `h5_entry` / `assistant_welcome` / `recommendation` / `task` / `health_advice` |
| **架构** | Web Component |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + 7 个 JSON 数据文件 |

### 数据变体

| JSON 文件 | card_type | 场景 |
|-----------|-----------|------|
| `h5-ai-assistant.json` | `h5_entry` | 聊天室 AI 助手入口 |
| `h5-essay.json` | `h5_entry` | 作文范文链接入口 |
| `edu-ai.json` | `assistant_welcome` | 教育场景 AI 助手欢迎页 |
| `medical-ai.json` | `assistant_welcome` | 医疗场景 AI 助手欢迎页 |
| `oral-practice.json` | `recommendation` | AI 推荐口语练习 |
| `weekly-report.json` | `task` | 多人协作教学周报 |
| `medication-reminder.json` | `health_advice` | 用药提醒 |

### 主题配色

| theme | 品牌色 | 适用场景 |
|-------|--------|---------|
| `general` | #3b82f6 | 通用、入口 |
| `ai` | #8b5cf6 | AI 助手 |
| `recommendation` | #0891b2 | 内容推荐 |
| `task` | #d97706 | 任务协作 |
| `health` | #059669 | 健康、医疗 |

---

## 2. 作业提醒 — [homework-card/](./homework-card/)

学科色条横幅模板，彩色渐变横幅 + 学科图标 + 标题 + 描述 + 按钮。

| 属性 | 值 |
|------|-----|
| **card_type** | `homework_reminder` |
| **架构** | Web Component |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `chinese.json` + `math.json` + `english.json` |

### 数据变体

| JSON 文件 | theme | 学科 |
|-----------|-------|------|
| `chinese.json` | `chinese` | 语文（红色渐变 #dc2626→#f87171） |
| `math.json` | `math` | 数学（蓝色渐变 #3b82f6→#60a5fa） |
| `english.json` | `english` | 英语（绿色渐变 #16a34a→#4ade80） |

---

## 3. 媒体预览 — [media-card/](./media-card/)

150px 暗色预览区 + 播放按钮 + 类型/时长标签，适用于视频、音频、图片、文件等媒体资源分享。

| 属性 | 值 |
|------|-----|
| **card_type** | `media_preview` |
| **架构** | Web Component |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `class-video.json` |

### 媒体类型

| layout.icon | 类型标签 | emoji |
|-------------|---------|-------|
| `video` | 视频 | 🎬 |
| `audio` | 音频 | 🎧 |
| `image` | 图片 | 🖼 |
| `file` | 文件 | 📄 |

---

## 4. 英语单词 — [english-word-card/](./english-word-card/)

字母/单词启蒙卡片。笔记本横线纸 + 胶带 + 缎带装饰，左侧大字母 + 右侧单词与实物图片，点击发音（Web Speech API）。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_word` |
| **架构** | Web Component |
| **主题色** | #8e44ad（紫色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |

### 英语卡片系列

| 卡片 | 目录 | 特点 |
|------|------|------|
| 英语单词 | english-word-card/ | 字母启蒙，缎带+胶带装饰，大字母+图片 |
| 英语句子展示 | english-sentence-card/ | 每日一句，缎带徽章，点击翻译 |
| 英语输入 | english-input-card/ | 自由输入，实时翻译，无缎带 |

---

## 5. 连环画 — [comic-card/](./comic-card/)

PEP 外研版英语连环画。Unit 切换标签 + 视频播放 + 分页漫画气泡 + 前后翻页导航。

| 属性 | 值 |
|------|-----|
| **card_type** | `comic_strip` |
| **架构** | Web Component |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `data.json` + `assets/image/` + `assets/video/` |
| **对应技能** | [comic-card/skill.md](./comic-card/skill.md) |

### 数据内容（6 Units）

| Unit | 主题 | Panels | 视频 |
|------|------|--------|------|
| 1 | Pets — Meet My Little Friends | 5 | ✓ |
| 2 | Animals — A Day at the Zoo | 6 | ✓ |
| 3 | Face — We Are Twins! | 6 | ✓ |
| 4 | Body — My Robot Monster | 4 | ✓ |
| 5 | My Home — Tidy Up Time | 6 | ✓ |
| 6 | Time — Happy Birthday, Dad! | 1 | ✓ |

### 交互方式

- **前后按钮**：翻页浏览同一 Unit 内的 panel
- **页码圆点**：点击跳转到指定 panel
- **触摸滑动**：在图片区域左右滑动导航
- **键盘**：← → 方向键翻页
- **Unit 标签**：6 个彩色标签切换不同单元

---

## 6. AI 问答 — [answer-card/](./answer-card/)

精简 AI 知识问答卡片，专注回答展示。无头部、无输入栏，配置硬编码在 JS 中，由外部调用渲染函数。

| 属性 | 值 |
|------|-----|
| **card_type** | `qa_answer` |
| **架构** | Standalone（纯 HTML + CSS + 原生 JS） |
| **API** | `POST /qa` → DeepSeek，top_k=5，超时 30s |
| **文件** | `index.html` + `style.css` + `app.js` |

### 与 Web Component 架构的区别

| 元素 | Web Component 卡片 | Answer 卡片 |
|------|-------------------|-------------|
| 头部 | ✅ | ❌ 无 |
| 顶部渐变流光条 | ❌ | ✅ 3px 五色 shimmer |
| 输入栏 | ❌ | ❌（外部驱动） |
| API 集成 | ❌ | ✅ DeepSeek |
| 文件来源展示 | ❌ | ✅ 6 种文件类型色标 |
| 配置方式 | data.json | JS 硬编码 |

---

## 7. 英语句子展示 — [english-sentence-card/](./english-sentence-card/)

每日一句展示卡片。笔记本横线纸 + 缎带徽章 + 英语句子 + 点击翻译 + TTS 发音 + 跟读评分。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_sentence` |
| **架构** | Web Component |
| **主题色** | #2563eb（蓝色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |

---

## 8. 英语输入 — [english-input-card/](./english-input-card/)

自由输入英语句子卡片。笔记本横线纸 + 可编辑 textarea + 600ms 防抖实时翻译 + TTS 发音 + 跟读评分。v1.1 起移除缎带，改为纯输入设计。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_sentence` |
| **架构** | Web Component |
| **主题色** | #ea580c（橙色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |

### 与 english-sentence-card 的差异

| 特性 | english-sentence-card | english-input-card |
|------|----------------------|-------------------|
| 缎带徽章 | ✅ 有 | ❌ 无（v1.1 移除） |
| 句子来源 | data.json 预设 | 用户自由输入 |
| 翻译方式 | 点击后显示（data 预设） | 600ms 防抖实时 API 翻译 |
| 主题色 | 蓝色 #2563eb | 橙色 #ea580c |

---

## 英语评分服务 — [services/english-scoring/](./services/english-scoring/)

Python 服务模块，调用 DeepSeek API 对三类英语卡片的跟读进行多维度 AI 评分。

| 属性 | 值 |
|------|-----|
| **框架** | FastAPI + Uvicorn |
| **端口** | 8800 |
| **API** | DeepSeek（deepseek-v4-pro） |
| **对应技能** | [services/english-scoring/skill.md](./services/english-scoring/skill.md) |

### 评分维度

| 卡片类型 | 维度 | 权重 |
|---------|------|------|
| english_word | 发音准确度 | 45% |
| | 完整性 | 25% |
| | 流利度 | 15% |
| | 语调自然度 | 15% |
| english_sentence | 发音准确度 | 35% |
| | 完整性 | 25% |
| | 流利度 | 20% |
| | 语调自然度 | 20% |
| english_input | 发音准确度 | 35% |
| | 完整性 | 25% |
| | 流利度 | 20% |
| | 语调自然度 | 20% |

---

## 响应式适配

所有卡片支持 5 设备断点：

| 设备 | 断点 | 典型卡片宽度 |
|------|------|-------------|
| 手机 | < 480px | 380px |
| 平板 | ≥ 480px | 420px |
| 大屏 | ≥ 768px | 460px |
| 桌面 | ≥ 1024px | 500px |
| 电视 | ≥ 1440px | 560px |

---

## 技能系统

### 卡片生成技能（`skills/`）

跨卡片通用技能，构成卡片生成流水线：`selector` → `resource_lookup` → `card_render`

| 技能 | 文件 | 职责 |
|------|------|------|
| selector | [skills/selector.md](../skills/selector.md) | 技能索引，路由到 resource_lookup 或 card_render |
| resource_lookup | [skills/resource_lookup.md](../skills/resource_lookup.md) | 搜索已有资源，输出结构化候选 |
| card_render | [skills/card_render.md](../skills/card_render.md) | 接收 templateId + data，渲染卡片 HTML |
| card | [skills/card.md](../skills/card.md) | 卡片生成入口，决策复用/新建模板 |
| image-generator | [skills/image-generator.md](../skills/image-generator.md) | 生成插图，替换 data.json 中的 target_url |

### 卡片专属技能

| 技能 | 位置 | 说明 |
|------|------|------|
| comic | [comic-card/skill.md](./comic-card/skill.md) | 连环画卡片生成，视频+分页面板 |
| english-scoring | [services/english-scoring/skill.md](./services/english-scoring/skill.md) | 英语口语 AI 评分，3 种评分模式 |

### 系统管理技能（`.claude/skills/`）

面向仓库管理和安全审计：

| 技能 | 文件 |
|------|------|
| 安全扫描 | `.claude/skills/security-audit.md` |
| 安全策略 | `.claude/skills/skill-security-policy.md` |
| 技能管理 | `.claude/skills/skill-manager.md` |
| 仓库管理 | `.claude/skills/gitee-repo.md` |
| 安全扫描器 | `.claude/skills/skill-security-scanner.md` |

---

## 每个卡片模板的标准文件

```
{card-name}/
├── index.html       # 页面入口（零逻辑或最小逻辑）
├── ai-card.css      # 卡片样式（Shadow DOM 内生效，5 设备响应式）
├── ai-card.js       # 渲染引擎（Web Component 或 原生 JS）
├── data.json        # 静态数据（一个或多个）
├── metadata.md      # 元数据文档
└── (可选) fonts/    # 本地字体文件
```

---
name: card
description: Generate AI cards. 3 visual templates (text / homework / media), each in its own folder with CSS + JS + JSON + metadata.
---

# /card — AI 卡片生成器

传入自然语言或 JSON，自动创建卡片 JSON 文件到对应模板文件夹，并更新 index.html 和 demo 页。

## 目录结构

```
h5卡片/
├── ai-card-demo.html            # 总览页
│
├── text-card/                   # 文本类卡片（7 张）
│   ├── index.html               # 展示所有文本类变体
│   ├── ai-card.css              # 文本卡片样式
│   ├── ai-card.js               # 文本卡片渲染（仅 defaultHTML）
│   ├── metadata.md
│   ├── h5-ai-assistant.json
│   ├── h5-essay.json
│   ├── edu-ai.json
│   ├── medical-ai.json
│   ├── oral-practice.json
│   ├── weekly-report.json
│   └── medication-reminder.json
│
├── homework-card/               # 作业类卡片（3 张）
│   ├── index.html
│   ├── ai-card.css              # 作业卡片样式（bar header）
│   ├── ai-card.js               # 作业卡片渲染（仅 homeworkHTML）
│   ├── metadata.md
│   ├── chinese.json
│   ├── math.json
│   └── english.json
│
├── media-card/                  # 媒体类卡片（1 张）
│   ├── index.html
│   ├── ai-card.css              # 媒体卡片样式（media area）
│   ├── ai-card.js               # 媒体卡片渲染（仅 mediaHTML）
│   ├── metadata.md
│   └── class-video.json
│
└── .claude/skills/card.md       # 本文件
```

**3 种视觉模板 → 3 个文件夹**，每个文件夹的 JS 仅包含当前模板的渲染代码。

---

## 3 种模板说明

### text-card — 文本类卡片
顶部渐变装饰条 + 左侧品牌色条 + 图标 + 标题 + 描述 + 按钮。

| card_type | 说明 | 常用 theme | 常用 icon |
|-----------|------|-----------|----------|
| `h5_entry` | H5 入口 | `blue_white` | `ai`, `link` |
| `assistant_welcome` | AI 助手欢迎 | `purple_white`, `emerald_white` | `ai` |
| `recommendation` | 内容推荐 | `cyan_white` | `audio`, `sparkle` |
| `task` | 任务协作 | `amber_white` | `task` |
| `health_advice` | 健康建议 | `emerald_white` | `health` |

### homework-card — 作业提醒卡片
学科色条横幅（标题 + 教师 + 学科标签）+ 描述 + 按钮。

| card_type | 说明 | theme → 学科 | icon |
|-----------|------|-------------|------|
| `homework_reminder` | 语文 | `red_white` | `chinese` |
| `homework_reminder` | 数学 | `blue_white` | `math` |
| `homework_reminder` | 英语 | `green_white` | `english` |

### media-card — 媒体预览卡片
150px 暗色预览区 + 播放按钮 + 类型标签 + 时长 + 标题 + 描述 + 按钮。

| card_type | 说明 | theme | icon |
|-----------|------|-------|------|
| `media_preview` | 视频/音频/图片/文件 | `indigo_white` | `video`, `audio`, `image`, `file` |

---

## 颜色方案

| theme | 品牌色 | 适用 |
|-------|--------|------|
| `blue_white` | #3b82f6 | 通用、数学 |
| `purple_white` | #8b5cf6 | AI 助手 |
| `red_white` | #dc2626 | 语文作业 |
| `green_white` | #16a34a | 英语作业 |
| `cyan_white` | #0891b2 | 内容推荐 |
| `amber_white` | #d97706 | 任务协作 |
| `emerald_white` | #059669 | 健康、医疗 |
| `indigo_white` | #4f46e5 | 媒体预览 |

---

## 工作流程

1. 用户说"生成一张数学作业卡片"
2. 判断模板类型：`homework-card`
3. 创建 JSON 文件（如 `homework-card/math.json`）：
   ```json
   {"schema_version":"1.0","card_type":"homework_reminder","title":"数学 · ...","subtitle":"...","description":"...","button_text":"查看作业","target_url":"https://...","theme":"blue_white","layout":{"variant":"homework_reminder","icon":"math"}}
   ```
4. 更新 `homework-card/index.html`，在 `CARDS` 数组中追加新卡片条目
5. 更新 `ai-card-demo.html`，在 `CARDS` 数组中追加新卡片条目
6. 在浏览器打开预览

## JSON Schema（严格遵守 AI卡片.md）

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "...",
  "subtitle": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "https://...",
  "theme": "..._white",
  "layout": { "variant": "...", "icon": "..." }
}
```

## 注意事项

1. **引号处理**：JSON 字符串内的中文引号用「」代替 ASCII 引号
2. **命名规范**：JSON 文件名用 kebab-case，按用途命名
3. **同步更新**：每次新增卡片，更新对应文件夹的 `index.html` 和根目录的 `ai-card-demo.html`
4. **模板匹配**：根据 card_type 放入正确的模板文件夹（text / homework / media）
5. **JS 精简**：每个文件夹的 `ai-card.js` 只包含当前模板的渲染代码，不包含其他模板的死代码
6. **自定义元素冲突**：`ai-card.js` 中 `customElements.define` 前已加 `customElements.get()` 守卫，兼容 demo 页同时加载多个 JS

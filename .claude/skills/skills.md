---
name: skills
description: Card template selector. Use when the user asks which card to use, how to invoke a card, or needs to pick a template (homework/media/answer/comic/word/text). Covers all 6 card types across Web Component and Standalone architectures.
---

# Skills — 卡片模板调用指南

本项目包含 **6 种卡片模板**，分为两套架构体系。本文档用于查找和调用每一种卡片。

---

## 目录

1. [快速查找：我需要哪种卡片？](#快速查找我需要哪种卡片)
2. [架构一览](#架构一览)
3. [Web Component 卡片](#web-component-卡片)
   - [text-card — 文本卡片](#1-text-card--文本卡片)
   - [homework-card — 作业提醒卡片](#2-homework-card--作业提醒卡片)
   - [media-card — 媒体预览卡片](#3-media-card--媒体预览卡片)
   - [english-word-card — 英语单词卡片](#4-english-word-card--英语单词卡片)
   - [comic-card — 连环画卡片](#5-comic-card--连环画卡片)
4. [Standalone 卡片](#standalone-卡片)
   - [Answer Card — 问答卡片·精简版](#6-answer-card--问答卡片精简版)
5. [通用 JSON Schema](#通用-json-schema)
6. [主题配色速查](#主题配色速查)
7. [响应式断点速查](#响应式断点速查)

---

## 快速查找：我需要哪种卡片？

| 场景 | 视觉特征 | 使用模板 |
|------|---------|---------|
| 通用入口 / AI 助手欢迎 / 内容推荐 / 任务协作 / 健康建议 | 顶部渐变条 + 左侧色条 + 图标 + 标题 + 描述 + 按钮 | [text-card](#1-text-card--文本卡片) |
| 学科作业提醒（语/数/英） | 彩色渐变横幅（图标+标题+学科标签）+ 描述 + 按钮 | [homework-card](#2-homework-card--作业提醒卡片) |
| 视频/音频/图片/文件预览 | 150px 暗色预览区 + 播放按钮 + 类型/时长标签 + 标题 | [media-card](#3-media-card--媒体预览卡片) |
| 英语字母/单词启蒙学习 | 笔记本横线纸 + 便利贴（胶带+缎带）+ 大字母 + 单词 + 图片 + 点击发音 | [english-word-card](#4-english-word-card--英语单词卡片) |
| 连环画/漫画分页阅读 | 视频播放器 + 单帧漫画（图片+气泡）+ 上一页/下一页 + 页码指示器 | [comic-card](#5-comic-card--连环画卡片) |
| AI 回答展示 | 顶部流光渐变条 + AI 头像 + "基于知识库"标签 + 渐变正文 + 彩色文件列表 | [Answer Card](#6-answer-card--问答卡片精简版) |

---

## 架构一览

| 架构 | 文件夹 | 渲染方式 | 入口文件 | 配置方式 |
|------|--------|---------|---------|---------|
| **Web Component** | text-card, homework-card, media-card, english-word-card, comic-card | `<ai-card data='{...}'>` → Shadow DOM | `index.html` + `ai-card.js` + `ai-card.css` | JSON 文件 + `FILES[]` 数组 |
| **Standalone** | answer-card | 传统 HTML/CSS/JS，直接操作 DOM | `index.html` + `style.css` + `app.js` | 硬编码配置 |

### Web Component 通用调用方式

```html
<!-- 1. 引入 CSS 和 JS -->
<link rel="stylesheet" href="text-card/ai-card.css">
<script src="text-card/ai-card.js"></script>

<!-- 2. 在页面中使用自定义元素 -->
<ai-card data='{"schema_version":"1.0","card_type":"h5_entry","title":"标题",...}'></ai-card>

<!-- 3. 或使用 JS 批量渲染 -->
<script>
  renderCards('root', [
    { folder: 'text-card', group: '入口', file: 'xxx.json', data: { /* ... */ } }
  ]);
</script>
```

### Standalone 通用调用方式

```html
<!-- 直接打开 index.html，或 iframe 嵌入 -->
<iframe src="answer-card/index.html" style="width:100%;max-width:600px;border:none;"></iframe>
```

---

## Web Component 卡片

### 1. text-card — 文本卡片

**文件夹：** `text-card/`

**视觉特征：** 顶部 3px 渐变装饰条 + 左侧 4px 品牌色竖条 + 42px 图标 + 标题/副标题/badge + 描述 + 按钮

**适用 card_type：** `h5_entry` | `assistant_welcome` | `recommendation` | `task` | `health_advice`

**调用方式：**

```js
// 方式一：直接在页面使用 Web Component
<ai-card data='{"card_type":"h5_entry","title":"炎图 AI 助手",...}'></ai-card>

// 方式二：修改 ai-card.js 底部 FILES 数组，然后打开 index.html
var FILES = ['h5-ai-assistant.json', 'h5-essay.json', 'your-new.json'];

// 方式三：在 ai-card-demo.html 的 CARDS 数组中添加
{folder:'text-card', group:'文本卡片', file:'your-new.json', data:{/* JSON */}},
```

**已有数据变体：**

| JSON 文件 | card_type | theme | 场景 |
|-----------|-----------|-------|------|
| `h5-ai-assistant.json` | h5_entry | general | 炎图 AI 助手入口 |
| `h5-essay.json` | h5_entry | general | 作文范文链接 |
| `edu-ai.json` | assistant_welcome | ai | 教育 AI 助手欢迎 |
| `medical-ai.json` | assistant_welcome | health | 医疗 AI 助手欢迎 |
| `oral-practice.json` | recommendation | recommendation | 口语练习推荐 |
| `weekly-report.json` | task | task | 教学周报协作 |
| `medication-reminder.json` | health_advice | emerald | 服药提醒 |

**支持的主题：** `general`(蓝) | `ai`(紫) | `recommendation`(青) | `task`(琥珀) | `health`(翠绿)

**支持的图标：** `ai` | `link` | `sparkle` | `task` | `health` | `audio`

---

### 2. homework-card — 作业提醒卡片

**文件夹：** `homework-card/`

**视觉特征：** 顶部彩色渐变横幅（图标+标题+副标题+学科标签）+ 下方描述 + 按钮

**适用 card_type：** `homework_reminder`

**调用方式：**

```js
<ai-card data='{"card_type":"homework_reminder","title":"语文 · 阅读理解训练","theme":"chinese",...}'></ai-card>
```

**已有数据变体：**

| JSON 文件 | theme | 学科 | 颜色 |
|-----------|-------|------|------|
| `chinese.json` | chinese | 语文 | 红 #dc2626 |
| `math.json` | math | 数学 | 蓝 #3b82f6 |
| `english.json` | english | 英语 | 绿 #16a34a |

**新增学科需要改 JS 中 3 处：** `PALETTE`(颜色) + `THEME_MAP`(theme→color) + `SUBJECT_LABEL`(theme→中文标签)

---

### 3. media-card — 媒体预览卡片

**文件夹：** `media-card/`

**视觉特征：** 150px 暗色预览区（#1e1b4b）+ 类型标签（左上）+ 播放按钮（居中）+ 时长标签（右下）+ 图标 + 标题 + 描述 + 按钮

**适用 card_type：** `media_preview`

**特殊行为：** `subtitle` 字段不显示为副标题，而是作为**时长标签**渲染在预览区右下角。

**调用方式：**

```js
<ai-card data='{"card_type":"media_preview","title":"课堂录像 · 分数的加减法","subtitle":"42:18","theme":"video",...}'></ai-card>
```

**已有数据变体：**

| JSON 文件 | theme | icon | 类型 |
|-----------|-------|------|------|
| `class-video.json` | video | video | 视频 |

**支持的媒体类型：** `video` | `audio` | `image` | `file`（全部使用 indigo #4f46e5 品牌色）

---

### 4. english-word-card — 英语单词卡片

**文件夹：** `english-word-card/`

**视觉特征：** 笔记本横线纸背景 + 半透明便利贴（胶带装饰+紫色缎带徽章）+ 左侧大字母（Aa）+ 右侧单词标签 + 实物图片 + 点击发音（Web Speech API）

**适用 card_type：** `english_word`

**特殊行为：**
- `subtitle` = 字母组合（如 "Aa"），渲染为左侧大号字母。首字符大写，其余小写
- `description` = 英文单词（如 "apple"），渲染为右侧单词标签 + 图片 alt
- `title` = 缎带徽章文字
- 点击字母/单词/图片均可发音（美式英语，语速 0.85，音调 1.1）

**调用方式：**

```js
<ai-card data='{"card_type":"english_word","title":"ABC · 字母启蒙","subtitle":"Aa","description":"apple","target_url":"https://.../apple.png","theme":"abc",...}'></ai-card>
```

**已有数据变体：**

| JSON 文件 | 字母 | 单词 | theme |
|-----------|------|------|-------|
| `data.json` | Aa | apple | abc |

**依赖：** Google Fonts — Patrick Hand 手写字体（需在 `<head>` 中加载）

---

### 5. comic-card — 连环画卡片

**文件夹：** `comic-card/`

**视觉特征：** 视频播放器 + 单元标签（6 色）+ 单帧漫画（图片+气泡）+ 页码指示器 + 页面圆点 + 上一页/下一页 + 触摸滑动/键盘导航

**适用 card_type：** `comic_strip`

**调用方式：**

```js
<ai-card data='{"card_type":"comic_strip","title":"We Are Twins!","frames":[{...}],...}'></ai-card>
```

**已有数据变体：**

| JSON 文件 | 单元数 | 面板数 | 视频数 |
|-----------|--------|--------|--------|
| `data.json` | 6 (PEP外研版 Units 1-6) | 28 | 6 |

**导航方式：** 上一页/下一页按钮 | 页面圆点跳转 | 触摸左右滑动 | 键盘 ← → 方向键

**气泡规则：** texts[0] → 蓝左 | texts[1] → 粉右 | texts[2+] → 绿居中加粗

**更多详情：** 参见 `.claude/skills/comic.md`

---

## Standalone 卡片

### 6. Answer Card — 问答卡片·精简版

**文件夹：** `answer-card/`

**视觉特征：** 顶部 3px 五色流光渐变条（4s 循环动画）+ AI 头像（"AI" 渐变方块）+ 绿色 "● 基于知识库" badge + 渐变背景正文（左侧 3px 紫蓝渐变竖线）+ 6 种文件类型彩色图标 + 外部输入栏

**调用方式：**

```html
<!-- 方式一：直接打开 -->
<!-- 浏览器打开 answer-card/index.html -->

<!-- 方式二：iframe 嵌入 -->
<iframe src="answer-card/index.html" style="width:100%;max-width:600px;border:none;"></iframe>
```

**配置方式：** 修改 `app.js` 中的硬编码常量

```js
const API_BASE   = 'http://127.0.0.1:8899';
const QA_URL     = API_BASE + '/qa';
const TOP_K      = 5;
const TIMEOUT_MS = 30000;
```

**API 依赖：**
- `POST /qa` ← `{ "question": "...", "top_k": 5 }` → `{ "description": "...", "sources": ["[cat] file.ext"] }`

**关键文件：**

| 文件 | 作用 |
|------|------|
| `index.html` | 静态骨架（所有 DOM 预声明） |
| `style.css` | 全部样式 + 4 断点 + 动画 |
| `app.js` | 配置、问答请求、DOM 渲染 |
| `metadata.md` | 卡片功能与配置信息 |

**文件类型色标（6 种）：**

| 扩展名 | 图标 | 背景色 | 徽章色 |
|--------|------|--------|--------|
| md | 📘 | #eef2ff | #4f46e5 |
| docx/doc | 📄 | #e0f2fe | #0369a1 |
| pptx/ppt | 📊 | #fef3c7 | #a16207 |
| pdf | 📕 | #fee2e2 | #b91c1c |
| xlsx/xls | 📈 | #dcfce7 | #15803d |
| txt | 📝 | #f3f4f6 | #4b5563 |

---

## 通用 JSON Schema

适用于 Web Component 卡片（text/homework/media/english-word/comic）：

```json
{
  "schema_version": "1.0",
  "card_type": "h5_entry",
  "title": "卡片标题",
  "subtitle": "副标题（可选）",
  "description": "描述文字（可选）",
  "button_text": "按钮文案（可选，有默认值）",
  "target_url": "https://example.com",
  "theme": "general",
  "layout": {
    "variant": "h5_entry",
    "icon": "ai"
  }
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `schema_version` | 是 | 固定 `"1.0"` |
| `card_type` | 是 | 必须与 `layout.variant` 一致 |
| `title` | 是 | 卡片主标题 |
| `subtitle` | 否 | 缺失则隐藏（media-card 中用作时长标签） |
| `description` | 否 | 缺失则隐藏（english-word-card 中用作单词） |
| `button_text` | 否 | 缺失则使用模板默认值 |
| `target_url` | 是 | 按钮跳转地址 |
| `theme` | 否 | 语义主题名，映射到品牌色 |
| `layout.variant` | 否 | 与 card_type 相同 |
| `layout.icon` | 否 | 图标 key，需在模板支持的列表中 |

> 连环画卡片（comic-card）额外需要 `video_url` 和 `frames[]` 字段，详见 `.claude/skills/comic.md`。

---

## 主题配色速查

| theme | 颜色 | 色值 | 卡片 |
|-------|------|------|------|
| `general` | 蓝 | #3b82f6 | text |
| `ai` | 紫 | #8b5cf6 | text |
| `recommendation` | 青 | #0891b2 | text |
| `task` | 琥珀 | #d97706 | text |
| `health` | 翠绿 | #059669 | text |
| `chinese` | 红 | #dc2626 | homework |
| `math` | 蓝 | #3b82f6 | homework |
| `english` | 绿 | #16a34a | homework |
| `video` / `audio` / `image` / `file` | 靛蓝 | #4f46e5 | media |
| `abc` | 紫 | #8e44ad | english-word |
| `comic` | 琥珀 | #f59e0b | comic |
| `answer` | 靛蓝 | #5b5fe3 | answer |

---

## 响应式断点速查

| 端 | 断点 | Web Component 卡片 max-width | Answer 卡片 max-width | 页面布局 |
|----|------|------------------------------|----------------------|---------|
| 手机 | < 480px | 380px | 600px | 单列居中 |
| 平板 | ≥ 480px | 420px | 600px | 单列居中 |
| 大屏 | ≥ 768px | 460px | 600px | 双列网格 |
| 电脑 | ≥ 1024px | 500px | 600px | 双/三列 |
| 电视 | ≥ 1440px | 560px | 600px | 三/四列 |

---

## 新增卡片流程

### 复用现有模板

1. 根据[快速查找表](#快速查找我需要哪种卡片)确定模板文件夹
2. **Web Component 模板：** 创建 JSON 数据文件 → 更新 `ai-card.js` 的 `FILES[]` → 更新 `ai-card-demo.html` 的 `CARDS[]`
3. **Standalone 模板：** 修改 `app.js` 中的硬编码常量 → 直接使用

### 创建全新模板

当所有 6 种模板都不匹配时，参见 `.claude/skills/card.md` 中的 "New Template Flow" 章节。

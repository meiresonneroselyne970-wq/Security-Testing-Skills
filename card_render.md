---
name: card_render
description: Render a card given templateId + data. Outputs ai_card HTML or webview attachment. Does NOT look up resources or decide business logic — pure rendering engine.
---

# card_render — 卡片渲染

**输入:** `templateId` + `data`（JSON）
**输出:** `ai_card` HTML 元素 或 webview attachment
**不查资源、不决定业务** — 纯渲染引擎。

---

## 职责边界

| 职责 | card_render（本技能） | resource_lookup（查找技能） |
|------|----------------------|---------------------------|
| 接收 templateId + data 渲染卡片 | ✅ | ❌ |
| 生成 `<ai-card>` HTML | ✅ | ❌ |
| 生成 iframe / webview | ✅ | ❌ |
| 查已有资源/数据文件 | ❌ | ✅ |
| 按分类/学科过滤候选 | ❌ | ✅ |
| 决定使用哪个模板 | ❌ | ✅（建议 templateId） |

**调用链:** `resource_lookup` → 用户确认候选 → `card_render` 渲染

---

## 输入契约

```json
{
  "templateId": "homework-card",
  "data": {
    "schema_version": "1.0",
    "card_type": "homework_reminder",
    "title": "数学 · 第三章分数练习",
    "subtitle": "王老师 · 三年级二班",
    "description": "完成课本第42-44页练习题…",
    "button_text": "查看作业",
    "target_url": "https://homework.example.com/math",
    "theme": "math",
    "layout": {
      "variant": "homework_reminder",
      "icon": "math"
    }
  }
}
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `templateId` | 是 | 6 个有效值之一（见下方） |
| `data` | 是 | 符合通用 JSON Schema 的卡片数据 |
| `data.schema_version` | 是 | 固定 `"1.0"` |
| `data.card_type` | 是 | 卡片类型标识 |
| `data.title` | 是 | 卡片主标题 |
| `data.target_url` | 是 | 按钮跳转地址 |

---

## 输出格式

### Web Component 模板（text / homework / media / english-word / comic）

输出 `ai_card` HTML 元素：

```html
<!-- 1. 引入 CSS 和 JS（每个页面只需一次） -->
<link rel="stylesheet" href="{templateId}/ai-card.css">
<script src="{templateId}/ai-card.js"></script>

<!-- 2. 使用自定义元素 -->
<ai-card data='{"schema_version":"1.0","card_type":"...","title":"...",...}'></ai-card>
```

### Standalone 模板（answer-card）

输出 webview / iframe attachment：

```html
<iframe src="answer-card/index.html"
  style="width:100%;max-width:600px;height:700px;border:none;">
</iframe>
```

> answer-card 是完整的独立应用（输入→API→渲染），不支持 `<ai-card>` 方式。只能通过 iframe 嵌入或直接打开 `index.html`。

---

## 支持的 templateId（6 个）

| templateId | 架构 | 渲染元素 | card_type 有效值 |
|------------|------|---------|-----------------|
| `text-card` | Web Component | `<ai-card>` | h5_entry, assistant_welcome, recommendation, task, health_advice |
| `homework-card` | Web Component | `<ai-card>` | homework_reminder |
| `media-card` | Web Component | `<ai-card>` | media_preview |
| `english-word-card` | Web Component | `<ai-card>` | english_word |
| `comic-card` | Web Component | `<ai-card>` | comic_strip |
| `answer-card` | Standalone | `<iframe>` | qa_answer |

---

## 通用 JSON Schema

适用于所有 Web Component 模板（text/homework/media/english-word/comic）：

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "卡片标题",
  "subtitle": "副标题（可选）",
  "description": "描述文字（可选）",
  "button_text": "按钮文案（可选，有默认值）",
  "target_url": "https://example.com",
  "theme": "general",
  "layout": {
    "variant": "...",
    "icon": "..."
  }
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `schema_version` | 是 | 固定 `"1.0"` |
| `card_type` | 是 | 必须与 `layout.variant` 一致 |
| `title` | 是 | 卡片主标题 |
| `subtitle` | 否 | 缺失则隐藏。media-card 中用作时长标签；english-word-card 中用作字母组合 |
| `description` | 否 | 缺失则隐藏。english-word-card 中用作中文释义 |
| `button_text` | 否 | 缺失使用模板默认值 |
| `target_url` | 是 | 按钮跳转地址 |
| `theme` | 否 | 语义主题名，映射到品牌色 |
| `layout.variant` | 否 | 与 card_type 相同 |
| `layout.icon` | 否 | 图标 key，需在模板支持的列表中 |

### 连环画额外字段

comic-card 额外需要：

| 字段 | 必填 | 说明 |
|------|------|------|
| `video_url` | 是 | 顶部视频地址 |
| `frames` | 是 | 漫画分镜数组，每个元素 `{ image, texts[] }` |

---

## 各模板渲染细节

### text-card

```
渲染元素: <ai-card data='...'>
引入文件: text-card/ai-card.css + text-card/ai-card.js
```

**支持的 icon:** `ai`, `link`, `sparkle`, `task`, `health`, `audio`
**支持的 theme:** `general`(蓝), `ai`(紫), `recommendation`(青), `task`(琥珀), `health`(翠绿)

### homework-card

```
渲染元素: <ai-card data='...'>
引入文件: homework-card/ai-card.css + homework-card/ai-card.js
```

**支持的 icon:** `chinese`, `math`, `english`
**支持的 theme:** `chinese`(红), `math`(蓝), `english`(绿)
**特殊:** theme 决定学科标签颜色和文字。新增学科需在 JS 中修改 PALETTE + THEME_MAP + SUBJECT_LABEL 三处。

### media-card

```
渲染元素: <ai-card data='...'>
引入文件: media-card/ai-card.css + media-card/ai-card.js
```

**支持的 icon:** `video`, `audio`, `image`, `file`
**支持的 theme:** `video`, `audio`, `image`, `file` (全部 indigo #4f46e5)
**特殊:** `subtitle` 用作时长标签（右下角），不显示为副标题。额外需要 `video_url` 字段。

### english-word-card

```
渲染元素: <ai-card data='...'>
引入文件: english-word-card/ai-card.css + english-word-card/ai-card.js
```

**支持的 icon:** `abc`
**支持的 theme:** `abc`(紫 #8e44ad)
**特殊字段映射:**
- `subtitle` → 左侧大字母（如 "Aa"），首字符大写，其余小写
- `description` → 中文释义（如 "苹果"）
- `title` → 缎带徽章文字
- 点击发音依赖 Web Speech API（美式英语，语速 0.85，音调 1.1）
- 需要在 `<head>` 中加载 Google Fonts: Patrick Hand

**Google Fonts 依赖（必须在页面 `<head>` 中）：**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Patrick+Hand&display=swap" rel="stylesheet">
```

### comic-card

```
渲染元素: <ai-card data='...'>
引入文件: comic-card/ai-card.css + comic-card/ai-card.js
```

**支持的 icon:** `comic`
**支持的 theme:** `comic`(琥珀 #f59e0b)
**特殊:** 需要 `video_url` 和 `frames[]`。frames 中 texts[0]→蓝左气泡, texts[1]→粉右气泡, texts[2+]→绿居中加粗。

### answer-card

```
渲染元素: <iframe src="answer-card/index.html">
引入文件: 无需（独立页面自带 style.css + app.js）
```

**特殊:** Standalone 架构。配置硬编码在 `app.js` 中（API_BASE、QA_URL、TOP_K、TIMEOUT_MS）。API 契约: `POST /qa` ← `{ "question": "...", "top_k": 5 }` → `{ "description": "...", "sources": ["[cat] file.ext"] }`。文件类型 6 色系统（md📘蓝/docx📄天蓝/pptx📊黄/pdf📕红/xlsx📈绿/txt📝灰）。

---

## 主题配色速查

| theme | 颜色 | 色值 | 模板 |
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

所有 Web Component 模板自动适配 5 个断点（CSS 内置于各模板的 `ai-card.css`）：

| 设备 | 断点 | 卡片最大宽度 | 布局 |
|------|------|-------------|------|
| 手机 | < 480px | 380px | 单列居中 |
| 平板 | ≥ 480px | 420px | 单列居中 |
| 大屏 | ≥ 768px | 460px | 双列网格 |
| 电脑 | ≥ 1024px | 500px | 双/三列 |
| 电视 | ≥ 1440px | 560px | 三/四列 |

> answer-card 固定 max-width: 600px，不随断点变化。

---

## 批量渲染

Web Component 模板支持 `renderCards()` 函数批量渲染：

```js
renderCards('root', [
  { folder: 'text-card', group: '入口', file: 'h5-ai-assistant.json', data: { /* ... */ } },
  { folder: 'homework-card', group: '作业', file: 'math.json', data: { /* ... */ } },
]);
```

---

## 注意事项

1. **纯渲染:** 不判断用哪个模板、不查找数据文件。templateId + data 由调用方（resource_lookup 或用户）提供。
2. **card_type 与 layout.variant 一致:** 两者必须相同，否则渲染异常。
3. **icon/theme 必须在支持列表中:** 使用不支持的 icon/theme 会导致空白或默认样式。
4. **引号处理:** JSON 字符串内的中文引号使用「」，避免与 ASCII 双引号冲突。
5. **Web Component 去重:** 多个模板的 JS 文件都定义 `<ai-card>`，但通过 `customElements.get('ai-card')` 检查避免重复注册。
6. **answer-card 不共享引擎:** 它不使用 `ai-card.js` / `ai-card.css`，是独立的 `app.js` + `style.css`。
7. **顺序依赖:** 必须先加载 CSS 再加载 JS，否则 Web Component 首次渲染时样式缺失。

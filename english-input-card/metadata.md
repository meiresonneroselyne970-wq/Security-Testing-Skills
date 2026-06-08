---
card_type: english_sentence
folder: english-input-card
version: "1.1"
---

# 英语句子输入卡片 (english-input-card)

英语句子学习卡片模板，笔记本横线纸背景 + 便利贴卡片，可编辑的英语句子输入框 + 实时中文翻译，点击发音（Web Speech API），支持跟读打分。

---

## 目录

1. [文件结构](#文件结构)
2. [JSON Schema](#json-schema)
3. [字段说明](#字段说明)
4. [HTML 渲染结构](#html-渲染结构)
5. [数据变体](#数据变体)
6. [主题配色](#主题配色)
7. [响应式适配](#响应式适配)
8. [渲染说明](#渲染说明)

---

## 文件结构

```
english-input-card/
├── index.html         # 页面入口（零逻辑，只声明 #root + 加载 JS/CSS）
├── ai-card.css        # 组件样式 + 页面样式 + 响应式断点（Shadow DOM 内外共用）
├── ai-card.js         # 渲染引擎（Web Component + 语音交互 + 跟读打分 + 实时翻译）
├── metadata.md        # 本文件
└── data.json          # 卡片数据
```

---

## JSON Schema

```json
{
  "schema_version": "1.0",
  "card_type": "english_sentence",
  "title": "每日一句",
  "subtitle": "The best preparation for tomorrow is doing your best today.",
  "description": "为明天做的最好准备，就是今天做到最好。",
  "button_text": "句子发音",
  "theme": "sentence",
  "layout": {
    "variant": "english_sentence",
    "icon": "sentence"
  }
}
```

---

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `schema_version` | string | 是 | 固定 `"1.0"` |
| `card_type` | string | 是 | 固定 `"english_sentence"` |
| `title` | string | 否 | 已废弃（v1.0 用于缎带徽章，v1.1 已移除缎带） |
| `subtitle` | string | 否 | 已废弃（v1.0 预填英文句子，v1.1 改为空文本框由用户自行输入） |
| `description` | string | 否 | 已废弃（v1.0 预填中文翻译，v1.1 改为 MyMemory API 实时翻译） |
| `button_text` | string | 否 | 按钮文案，默认"句子发音" |
| `theme` | string | 否 | 默认 `"sentence"`，THEME_MAP 映射到 orange |
| `layout.variant` | string | 否 | 固定 `"english_sentence"` |
| `layout.icon` | string | 否 | 固定 `"sentence"` |

---

## HTML 渲染结构

`ai-card.js` 中 `cardHTML(d)` 生成的 DOM 树：

```
<div class="sentence-card">                         ← 便利贴卡片（笔记本横线纸 + 圆角 + 阴影）
  <div class="sentence-body">                        ← 卡片内容区
    <div class="sentence-text-area">               ← 输入区
      <textarea class="sentence-en sentence-input"  ← 英语句子输入框（左对齐，自动撑高，placeholder="输入英语句子…"）
                placeholder="输入英语句子…"
                rows="1"></textarea>
      <div class="sentence-zh">                    ← 中文实时翻译（默认空，输入英文后 600ms 防抖自动翻译并淡入显示）
      </div>
    </div>
    <div class="actions">                            ← 按钮区
      <button class="btn primary">句子发音</button>    ← 橙色圆角按钮
      <button class="btn shadow">跟读</button>         ← 跟读按钮（镂空样式，浏览器支持语音识别时显示）
    </div>
    <div class="shadow-feedback"></div>               ← 跟读反馈区（正确/错误/录音回放）
  </div>
</div>
```

### 页面级包装（仅 standalone index.html）

```
body
  └── #root
        └── <ai-card>  ← Web Component 渲染的便利贴卡片
```

### 交互行为

| 元素 | 触发 | 行为 |
|------|------|------|
| `.sentence-en` (textarea) | input | 自动撑高 + 600ms 防抖实时英译中 |
| `.btn.primary` | click | 朗读输入框中的英语句子 |
| `.btn.shadow` | click | 先播放 TTS 范读 → 自动开启麦克风跟读 → 相似度打分反馈 |

朗读使用 `Web Speech API`（`speechSynthesis`），语速 0.8，音调 1.0，美式英语。浏览器不支持时静默跳过。

跟读使用 `Web Speech API`（`SpeechRecognition`），通过**词重叠相似度**（word overlap similarity ≥ 60%）判断是否正确，最多重试 3 次。

实时翻译使用 DeepSeek API（`deepseek-v4-pro` 模型），POST JSON 方式调用，system prompt 约束只输出中文译文，temperature 0.3。翻译中显示"翻译中…"，翻译失败自动隐藏。

### 自适应规则

| 字段状态 | 行为 |
|---------|------|
| `button_text` 缺失 | 按钮显示默认文案"句子发音" |
| `speechSynthesis` 不可用 | 点击无反应，无报错 |
| `SpeechRecognition` 不可用 | 跟读按钮不渲染 |
| 输入框为空 | 翻译隐藏，按钮无效 |
| 翻译 API 失败 | `.sentence-zh` 自动隐藏 |

---

## 数据变体

### data.json — 每日一句
| 属性 | 值 |
|------|-----|
| 按钮文案 | 句子发音 |
| theme | `sentence` |
| icon | `sentence` |

> v1.1 起卡片不再依赖数据中的句子内容，用户自行输入英语句子，翻译实时获取。

---

## 主题配色

| theme | 品牌色 | 浅色背景 | 柔和色 | 适用场景 |
|-------|--------|---------|--------|---------|
| `sentence` | #ea580c | #fff7ed | #fed7aa | 英语句子（默认） |
| `abc` | #8e44ad | #f5f3ff | #ede9fe | 字母/单词（兼容） |
| `blue` | #2563eb | #eff6ff | #dbeafe | 蓝色（保留） |

> 按钮、跟读按钮边框、中文翻译、反馈文字使用品牌色。`sentence` 主题默认使用橙色（#ea580c）。

---

## 响应式适配

5 端适配断点（`ai-card.css` 统一管理）：

| 端 | 断点 | 句子字号 | 卡片宽度 |
|----|------|---------|---------|
| 手机端 | < 480px | 28px | 420px |
| 平板端 | ≥ 480px | 30px | 460px |
| 大屏端 | ≥ 768px | 34px | 500px |
| 电脑端 | ≥ 1024px | 38px | 540px |
| 电视端 | ≥ 1440px | 42px | 600px |

### 缩放策略

- **句子字号**：从 28px → 42px（~+50%），适配各端阅读距离
- **句子对齐**：左对齐，多行换行时自动撑高
- **页面布局**：始终单列居中，适合学习场景

---

## 渲染说明

1. **笔记本横线纸背景**：`.sentence-card` 使用三层 CSS 背景（repeating 横线 + 米黄底色），模拟真实笔记本纸张
2. **可编辑输入框**：`<textarea>` 替代静态文本，用户自由输入英语句子，`rows="1"` 默认单行，输入长句自动撑高
3. **实时翻译**：输入时 600ms 防抖调用 MyMemory API（en → zh），结果显示在 `.sentence-zh`，淡入动画；清空输入框时自动隐藏
4. **语音交互**：点击按钮朗读输入框当前内容，通过 `getSentence()` 实时读取
5. **跟读打分**：使用词重叠相似度算法（word overlap similarity）判断发音准确性，≥60% 即认为正确
6. **录音回放**：跟读时自动录音，反馈区显示「听我的发音」按钮，点击可回放自己的录音与范读对比
7. **CSS 精简**：`ai-card.css` 包含组件样式（`.sentence-card`、`.sentence-en` 等）和页面样式，不含冗余规则
8. **PALETTE + THEME_MAP**：JS 中定义 purple、orange、blue 三种配色，`THEME_MAP` 将 `sentence` 映射到 orange、`abc` 映射到 purple
9. **Google Fonts**：使用 Patrick Hand 手写字体，在 `index.html` `<head>` 中加载
10. **无缎带设计**：v1.1 移除 `sentence-ribbon` 缎带徽章，卡片更简洁

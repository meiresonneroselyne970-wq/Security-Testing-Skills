# 8. 英语输入 — [english-input-card/](./english-input-card/)

自由输入英语句子卡片。笔记本横线纸 + 可编辑 textarea + 600ms 防抖实时翻译 + TTS 发音 + 跟读评分。v1.1 起移除缎带，改为纯输入设计。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_sentence` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **主题色** | #ea580c（橙色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |
| **对应技能** | [english-scoring](english-scoring.md)（英语口语 AI 评分） |

---

## 与 english-sentence-card 的差异

| 特性 | english-sentence-card | english-input-card |
|------|----------------------|-------------------|
| 缎带徽章 | ✅ 有 | ❌ 无（v1.1 移除） |
| 句子来源 | data.json 预设 | 用户自由输入 |
| 翻译方式 | 点击后显示（data 预设） | 600ms 防抖实时 API 翻译 |
| 主题色 | 蓝色 #2563eb | 橙色 #ea580c |

## 视觉特征

- 笔记本横线纸背景
- 可编辑 textarea（placeholder: "输入英语句子..."）
- 实时翻译显示区
- TTS 发音按钮
- 跟读评分按钮 → 调用英语评分服务

## 交互

| 操作 | 行为 |
|------|------|
| 输入文本 | 600ms 防抖 → 实时 API 翻译 |
| 点击发音按钮 | Web Speech API TTS 朗读输入内容 |
| 点击跟读按钮 | 语音识别 → fetch 评分 API → 展示多维度评分 |

## 文件结构

```
english-input-card/
├── index.html         # 页面入口（零逻辑）
├── ai-card.css        # 卡片样式
├── ai-card.js         # 渲染引擎（Web Component + textarea + 实时翻译 + 跟读评分）
├── fonts/             # 本地字体（Patrick Hand woff2）
├── metadata.md        # 元数据文档
└── data.json          # 初始数据
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [english-input-card/metadata.md](./english-input-card/metadata.md)
>
> 评分服务文档见 [english-scoring](english-scoring.md)

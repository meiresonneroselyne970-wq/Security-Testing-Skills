# 7. 英语句子展示 — [english-sentence-card/](./english-sentence-card/)

每日一句展示卡片。笔记本横线纸 + 缎带徽章 + 英语句子 + 点击翻译 + TTS 发音 + 跟读评分。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_sentence` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **主题色** | #2563eb（蓝色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |
| **对应技能** | [english-scoring](english-scoring.md)（英语口语 AI 评分） |

---

## 视觉特征

- 笔记本横线纸背景
- 蓝色缎带徽章（"每日一句"）
- 英语句子（大号 Patrick Hand 手写字体）
- 点击显示中文翻译
- TTS 发音按钮
- 跟读评分按钮 → 调用英语评分服务

## 交互

| 操作 | 行为 |
|------|------|
| 点击句子区域 | 切换显示中文翻译 |
| 点击发音按钮 | Web Speech API TTS 范读 |
| 点击跟读按钮 | 语音识别 → fetch 评分 API → 展示多维度评分 |

## 文件结构

```
english-sentence-card/
├── index.html         # 页面入口（零逻辑）
├── ai-card.css        # 卡片样式
├── ai-card.js         # 渲染引擎（Web Component + 翻译 + TTS + 跟读评分）
├── fonts/             # 本地字体（Patrick Hand woff2）
├── metadata.md        # 元数据文档
└── data.json          # 每日一句数据
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [english-sentence-card/metadata.md](./english-sentence-card/metadata.md)
>
> 评分服务文档见 [english-scoring](english-scoring.md)

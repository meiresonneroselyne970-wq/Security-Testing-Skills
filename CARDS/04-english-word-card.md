# 4. 英语单词 — [english-word-card/](./english-word-card/)

字母/单词启蒙卡片。笔记本横线纸 + 胶带 + 缎带装饰，左侧大字母 + 右侧单词与实物图片，点击发音（Web Speech API）。

| 属性 | 值 |
|------|-----|
| **card_type** | `english_word` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **主题色** | #8e44ad（紫色） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `fonts/` + `data.json` |
| **对应技能** | [english-scoring](english-scoring.md)（英语口语 AI 评分） |

---

## 英语卡片系列

| 卡片 | 目录 | 特点 |
|------|------|------|
| 英语单词 | english-word-card/ | 字母启蒙，缎带+胶带装饰，大字母+图片 |
| 英语句子展示 | english-sentence-card/ | 每日一句，缎带徽章，点击翻译 |
| 英语输入 | english-input-card/ | 自由输入，实时翻译，无缎带 |

## 视觉特征

- 笔记本横线纸背景（三层 CSS：光晕 + repeating 横线 + 米黄底）
- 便利贴卡片（半透明白底 + 圆角 + 阴影）
- 胶带装饰（顶部居中，半透明白色 + 虚线边）
- 紫色缎带徽章（左上角，微微左倾）
- 左侧大字母（大写 60px + 小写 40px，文字阴影）
- 右侧单词标签 + 实物图片

## 交互

| 元素 | 行为 |
|------|------|
| 大字母 | 点击朗读字母（Web Speech API） |
| 单词标签 | 点击朗读单词 |
| 实物图片 | 点击朗读单词 |

## 文件结构

```
english-word-card/
├── index.html         # 页面入口（零逻辑）
├── ai-card.css        # 卡片样式 + 页面样式 + 响应式
├── ai-card.js         # 渲染引擎（Web Component + 语音交互）
├── fonts/             # 本地字体（Patrick Hand woff2）
│   ├── fonts.css
│   ├── patrick-hand-latin-ext.woff2
│   ├── patrick-hand-latin.woff2
│   └── patrick-hand-vietnamese.woff2
├── metadata.md        # 元数据文档
└── data.json          # Aa · apple 卡片数据
```

---

> 详细 JSON Schema、DOM 结构、响应式适配、Android & 华为适配见 [english-word-card/metadata.md](./english-word-card/metadata.md)

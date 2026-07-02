# 2. 作业提醒 — [homework-card/](./homework-card/)

学科色条横幅模板，彩色渐变横幅 + 学科图标 + 标题 + 描述 + 按钮。

| 属性 | 值 |
|------|-----|
| **card_type** | `homework_reminder` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `chinese.json` + `math.json` + `english.json` |
| **对应技能** | 无（使用通用渲染流水线） |

---

## 数据变体

| JSON 文件 | theme | 学科 |
|-----------|-------|------|
| `chinese.json` | `chinese` | 语文（红色渐变 #dc2626→#f87171） |
| `math.json` | `math` | 数学（蓝色渐变 #3b82f6→#60a5fa） |
| `english.json` | `english` | 英语（绿色渐变 #16a34a→#4ade80） |

## 视觉特征

- 彩色渐变横幅（占卡片上部 ~100px）
- 学科图标（📖 语文 / 🧮 数学 / 🌍 英语）
- 学科标签 badge
- 标题 + 描述 + 操作按钮

## 文件结构

```
homework-card/
├── index.html       # 页面入口（零逻辑）
├── ai-card.css      # 卡片样式（含 .bar 横幅样式）
├── ai-card.js       # 渲染引擎
├── metadata.md      # 元数据文档
├── chinese.json     # 语文作业
├── math.json        # 数学作业
└── english.json     # 英语作业
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [homework-card/metadata.md](./homework-card/metadata.md)

# 1. 文本卡片 — [text-card/](./text-card/)

通用文本类卡片，覆盖 5 种 card_type。顶部渐变装饰条 + 左侧品牌色条 + 图标 + 标题 + 描述 + 按钮。

| 属性 | 值 |
|------|-----|
| **card_type** | `h5_entry` / `assistant_welcome` / `recommendation` / `task` / `health_advice` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + 7 个 JSON 数据文件 |
| **对应技能** | 无（使用通用渲染流水线） |

---

## 数据变体

| JSON 文件 | card_type | 场景 |
|-----------|-----------|------|
| `h5-ai-assistant.json` | `h5_entry` | 聊天室 AI 助手入口 |
| `h5-essay.json` | `h5_entry` | 作文范文链接入口 |
| `edu-ai.json` | `assistant_welcome` | 教育场景 AI 助手欢迎页 |
| `medical-ai.json` | `assistant_welcome` | 医疗场景 AI 助手欢迎页 |
| `oral-practice.json` | `recommendation` | AI 推荐口语练习 |
| `weekly-report.json` | `task` | 多人协作教学周报 |
| `medication-reminder.json` | `health_advice` | 用药提醒 |

## 主题配色

| theme | 品牌色 | 适用场景 |
|-------|--------|---------|
| `general` | #3b82f6 | 通用、入口 |
| `ai` | #8b5cf6 | AI 助手 |
| `recommendation` | #0891b2 | 内容推荐 |
| `task` | #d97706 | 任务协作 |
| `health` | #059669 | 健康、医疗 |

## 文件结构

```
text-card/
├── index.html              # 页面入口（零逻辑）
├── ai-card.css             # 卡片样式（Shadow DOM 内生效）
├── ai-card.js              # 渲染引擎（Web Component + 列表渲染）
├── metadata.md             # 元数据文档
├── h5-ai-assistant.json    # H5 入口 · 炎图 AI 助手
├── h5-essay.json           # H5 入口 · 作文范文
├── edu-ai.json             # AI 助手 · 教育场景
├── medical-ai.json         # AI 助手 · 医疗场景
├── oral-practice.json      # 内容推荐 · 口语练习
├── weekly-report.json      # 任务协作 · 教学周报
└── medication-reminder.json # 健康建议 · 服药提醒
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [text-card/metadata.md](./text-card/metadata.md)

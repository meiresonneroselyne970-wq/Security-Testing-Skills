# 6. AI 问答 — [answer-card/](./answer-card/)

精简 AI 知识问答卡片，专注回答展示。无头部、无输入栏，配置硬编码在 JS 中，由外部调用渲染函数。

| 属性 | 值 |
|------|-----|
| **card_type** | `qa_answer` |
| **架构** | Standalone（纯 HTML + CSS + 原生 JS，不使用 Shadow DOM） |
| **API** | `POST /qa` → DeepSeek，top_k=5，超时 30s |
| **文件** | `index.html` + `style.css` + `app.js` |
| **对应技能** | 无（独立架构，外部驱动） |

---

## 与 Web Component 架构的区别

| 元素 | Web Component 卡片 | Answer 卡片 |
|------|-------------------|-------------|
| 头部 | ✅ | ❌ 无 |
| 顶部渐变流光条 | ❌ | ✅ 3px 五色 shimmer |
| 输入栏 | ❌ | ❌（外部驱动） |
| API 集成 | ❌ | ✅ DeepSeek |
| 文件来源展示 | ❌ | ✅ 6 种文件类型色标 |
| 配置方式 | data.json | JS 硬编码 |

## 状态切换

| 状态 | 触发条件 | DOM |
|------|---------|-----|
| 空闲 | 页面加载后 | 💡 + 引导文案 |
| 加载中 | `showLoading()` | 三个跳动圆点 |
| 回答 | `renderAnswer(data)` | AI 头像 + 正文 + 来源文件 |
| 空结果 | 无有效内容 | 🤔 + "未找到相关内容" |
| 错误 | API 返回 error | ⚠️ 粉红背景 + 错误详情 |

## 文件类型色标

| 扩展名 | 图标 | 图标背景色 |
|--------|------|-----------|
| `md` | 📘 | #eef2ff（蓝） |
| `docx` / `doc` | 📄 | #e0f2fe（天蓝） |
| `pptx` / `ppt` | 📊 | #fef3c7（黄） |
| `pdf` | 📕 | #fee2e2（红） |
| `xlsx` / `xls` | 📈 | #dcfce7（绿） |
| `txt` | 📝 | #f3f4f6（灰） |
| 其他 | 📎 | #f3f4f6（灰） |

## 文件结构

```
answer-card/
├── index.html       # 页面入口（卡片骨架）
├── style.css        # 卡片样式（渐变装饰条 + 文件类型色标 + shimmer 动画）
├── app.js           # 渲染逻辑（DOM 渲染 + 状态切换，配置硬编码）
└── metadata.md      # 元数据文档
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [answer-card/metadata.md](./answer-card/metadata.md)

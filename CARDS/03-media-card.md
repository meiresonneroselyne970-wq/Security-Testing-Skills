# 3. 媒体预览 — [media-card/](./media-card/)

150px 暗色预览区 + 播放按钮 + 类型/时长标签，适用于视频、音频、图片、文件等媒体资源分享。

| 属性 | 值 |
|------|-----|
| **card_type** | `media_preview` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `class-video.json` |
| **对应技能** | 无（使用通用渲染流水线） |

---

## 媒体类型

| layout.icon | 类型标签 | emoji |
|-------------|---------|-------|
| `video` | 视频 | 🎬 |
| `audio` | 音频 | 🎧 |
| `image` | 图片 | 🖼 |
| `file` | 文件 | 📄 |

## 视觉特征

- 150px 暗色预览区（#1e1e2e 背景）
- 居中播放按钮（半透明白色圆形 + ▶ 图标）
- 类型标签 + 时长标签（右下角）
- 标题 + 描述 + 操作按钮

## 文件结构

```
media-card/
├── index.html        # 页面入口（零逻辑）
├── ai-card.css       # 卡片样式（含 .media-area 暗色预览区）
├── ai-card.js        # 渲染引擎
├── metadata.md       # 元数据文档
└── class-video.json  # 课堂视频预览
```

---

> 详细 JSON Schema、DOM 结构、响应式适配见 [media-card/metadata.md](./media-card/metadata.md)

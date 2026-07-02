# 5. 连环画 — [comic-card/](./comic-card/)

PEP 外研版英语连环画。Unit 切换标签 + 视频播放 + 分页漫画气泡 + 前后翻页导航。

| 属性 | 值 |
|------|-----|
| **card_type** | `comic_strip` |
| **架构** | Web Component（`<ai-card>` + Shadow DOM） |
| **文件** | `index.html` + `ai-card.css` + `ai-card.js` + `data.json` + `assets/image/` + `assets/video/` |
| **对应技能** | [comic-card/skill.md](./comic-card/skill.md) — 连环画卡片专用生成器 |

---

## 数据内容（6 Units）

| Unit | 主题 | Panels | 视频 |
|------|------|--------|------|
| 1 | Pets — Meet My Little Friends | 5 | ✓ |
| 2 | Animals — A Day at the Zoo | 6 | ✓ |
| 3 | Face — We Are Twins! | 6 | ✓ |
| 4 | Body — My Robot Monster | 4 | ✓ |
| 5 | My Home — Tidy Up Time | 6 | ✓ |
| 6 | Time — Happy Birthday, Dad! | 1 | ✓ |

## 交互方式

- **前后按钮**：翻页浏览同一 Unit 内的 panel
- **页码圆点**：点击跳转到指定 panel
- **触摸滑动**：在图片区域左右滑动导航
- **键盘**：← → 方向键翻页
- **Unit 标签**：6 个彩色标签切换不同单元

## DOM 骨架

```
comic-card
  ├── video-area → <video controls>
  └── card-body
        ├── hdr (title + subtitle)
        ├── desc (description)
        ├── comic-viewport (single frame)
        │     ├── page-indicator ("1 / 6")
        │     ├── frame-img
        │     └── bubbles (left blue / right pink / center green)
        └── nav (prev / next buttons)
```

## 气泡规则

| 位置 | 颜色 | 触发 |
|------|------|------|
| `.bubble.left` | 蓝色 | texts[0] |
| `.bubble.right` | 粉色 | texts[1] |
| `.bubble.center` | 绿色 | texts[2+] |

## 文件结构

```
comic-card/
├── index.html       # 页面入口（零逻辑）
├── ai-card.css      # 卡片样式（视频 + 漫画 + 气泡 + 导航）
├── ai-card.js       # 渲染引擎（Web Component + 分页 + Unit 切换）
├── data.json        # 6 Units 漫画数据
├── metadata.md      # 元数据文档
└── skill.md         # 连环画卡片专用生成技能
```

---

> 详细 JSON Schema、字段说明、响应式设计见 [comic-card/skill.md](./comic-card/skill.md) 和 [comic-card/metadata.md](./comic-card/metadata.md)

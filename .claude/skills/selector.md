---
name: selector
description: Card template selector hub. Use to find the right skill — resource_lookup (find resources) or card_render (render cards). Quick reference for all 6 card types.
---

# selector — 卡片技能索引

本项目卡片系统拆分为 **查找** 和 **渲染** 两套独立技能。

---

## 两套技能

```
用户需求
    │
    ├─ "有哪些数学作业?" ──→ resource_lookup（查资源）
    │                              │
    │                              └─→ 输出结构化候选 JSON
    │                                      │
    │                             用户确认候选
    │                                      │
    │                                      ▼
    └─ "渲染这张卡片"  ←────────── card_render（渲染卡片）
                                        │
                                        └─→ 输出 <ai-card> 或 <iframe>
```

| 技能 | 文件 | 做什么 | 不做什么 |
|------|------|--------|---------|
| **resource_lookup** | [resource_lookup.md](resource_lookup.md) | 查已有资源（作业/课本/活动/媒体…），输出候选 JSON | 不渲染卡片 |
| **card_render** | [card_render.md](card_render.md) | 输入 templateId + data → 输出 ai_card / webview | 不查资源、不决定业务 |

---

## 其他相关技能

| 技能 | 文件 | 用途 |
|------|------|------|
| **card** | [card.md](card.md) | 新建卡片数据文件或创建全新模板（6 种模板的完整参考） |
| **comic** | [comic.md](comic.md) | 连环画卡片专用生成器 |

---

## 快速查找：我需要哪种卡片？

| 场景 | 视觉特征 | templateId | card_type |
|------|---------|------------|-----------|
| 通用入口 / AI 助手 / 推荐 / 任务 / 健康建议 | 顶部渐变条 + 左侧色条 + 图标 + 标题 + 按钮 | `text-card` | h5_entry / assistant_welcome / recommendation / task / health_advice |
| 学科作业提醒（语/数/英） | 彩色渐变横幅 + 学科标签 + 描述 + 按钮 | `homework-card` | homework_reminder |
| 视频/音频/图片/文件预览 | 150px 暗色预览区 + 播放按钮 + 时长标签 | `media-card` | media_preview |
| 英语字母/单词启蒙 | 笔记本横线纸 + 便利贴 + 大字母 + 单词 + 图片 + 发音 | `english-word-card` | english_word |
| 连环画/漫画分页 | 视频播放器 + 单帧漫画气泡 + 上一页/下一页 | `comic-card` | comic_strip |
| AI 问答展示 | 流光渐变条 + AI 头像 + "基于知识库" badge + 彩色文件列表 | `answer-card` | qa_answer |

---

## 调用示例

### 查找资源

```
用户: "有哪些数学相关的卡片?"

→ 调用 resource_lookup 技能
→ 输出: { candidates: [{ templateId: "homework-card", file: "math.json", ... }] }
```

### 渲染卡片

```
用户: 确认使用 math.json

→ 调用 card_render 技能
→ 输入: { templateId: "homework-card", data: { ... math.json 内容 ... } }
→ 输出:
  <link rel="stylesheet" href="homework-card/ai-card.css">
  <script src="homework-card/ai-card.js"></script>
  <ai-card data='{"card_type":"homework_reminder","title":"数学 · 第三章分数练习",...}'></ai-card>
```

---

## 架构一览

| 架构 | 模板 | 渲染元素 |
|------|------|---------|
| **Web Component** | text, homework, media, english-word, comic | `<ai-card data='{...}'>` → Shadow DOM |
| **Standalone** | answer | `<iframe src="answer-card/index.html">` |

> 详细渲染说明、JSON Schema、主题配色、响应式断点见 [card_render.md](card_render.md)。

---

## 注意事项

1. **查找与渲染分离:** `resource_lookup` 只返回候选，不渲染；`card_render` 只渲染，不查资源。
2. **templateId 必须准确:** 6 个有效值 — `text-card`, `homework-card`, `media-card`, `english-word-card`, `comic-card`, `answer-card`。
3. **新增卡片数据:** 复用现有模板 → 参见 [card.md](card.md)；创建全新模板 → 同上。
4. **answer-card 特殊:** Standalone 架构，不支持 `<ai-card>`，只能用 iframe。无 JSON 数据变体。

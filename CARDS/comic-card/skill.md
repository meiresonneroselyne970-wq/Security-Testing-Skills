---
name: comic-card
description: PEP 外研版英语连环画卡片。Unit 切换标签 + 视频播放 + 分页漫画气泡 + 前后翻页导航，支持触摸滑动和键盘操作。
---

PEP 外研版英语连环画卡片模板，Unit 切换标签 + 视频播放 + 分页漫画气泡 + 前后翻页导航，支持触摸滑动和键盘操作。

---

## 目录

1. [文件结构](#文件结构)
2. [JSON Schema](#json-schema)
3. [字段说明](#字段说明)
4. [HTML 渲染结构](#html-渲染结构)
5. [对话气泡规则](#对话气泡规则)
6. [Unit 标签页](#unit-标签页)
7. [导航交互](#导航交互)
8. [响应式适配](#响应式适配)
9. [主题配色](#主题配色)
10. [数据概览](#数据概览)

---

## 文件结构

```
comic-card/
├── index.html            # 页面入口（零逻辑，只声明 #root + 加载 JS/CSS）
├── ai-card.js             # Web Component：Unit 切换、分页、滑动/键盘导航
├── ai-card.css            # 所有样式：标签页、气泡、圆点、过渡、5 端响应式
├── data.json              # 6 个 PEP 外研版 Unit，28 个漫画面板，6 个活动视频
├── assets/
│   ├── image/             # 28 张面板 PNG（unit1-6_panelN.png）
│   └── video/             # 6 个活动 MP4（unit1-6_activity1.mp4）
├── Educational Card/      # 原始素材（原始 JSON + Unit 文件夹）
└── skill.md               # 本文件
```

---

## JSON Schema

```json
{
  "schema_version": "1.0",
  "card_type": "comic_strip",
  "title": "Unit 1 Pets",
  "subtitle": "Meet My Little Friends",
  "description": "PEP 外研版英语连环画…",
  "button_text": "",
  "video_url": "../../assets/video/unit1_activity1.mp4",
  "theme": "comic",
  "frames": [
    {
      "image": "../../assets/image/unit1_panel1.png",
      "texts": ["Hello!", "Hi there!", "Let's go!"]
    }
  ],
  "layout": {
    "variant": "comic_strip",
    "icon": "comic"
  }
}
```

---

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `schema_version` | string | 是 | 固定 `"1.0"` |
| `card_type` | string | 是 | 固定 `"comic_strip"` |
| `title` | string | 是 | 卡片标题 |
| `subtitle` | string | 否 | 副标题，显示在标题下方 |
| `description` | string | 否 | 封面简介，显示在漫画上方 |
| `button_text` | string | 否 | 不渲染（前后翻页按钮替代） |
| `video_url` | string | 是 | `<video controls>` 视频源 |
| `theme` | string | 否 | 默认 `"comic"`，每个 Unit 有独立品牌色 |
| `frames` | array | 是 | 漫画帧数组 |
| `frames[].image` | string | 是 | 帧图片 URL |
| `frames[].texts` | array | 是 | 对话文本数组（每帧 0-3 条） |
| `layout.variant` | string | 否 | 固定 `"comic_strip"` |
| `layout.icon` | string | 否 | 图标键，默认 `"comic"` |

---

## HTML 渲染结构

`ai-card.js` 生成的 DOM 树：

```
ai-card (Shadow DOM)
  └── .comic-card
        ├── .unit-tabs                           ← Unit 切换标签栏（6 个标签，各不同颜色）
        │     └── .unit-tab[data-unit="N"]
        │           ├── .unit-tab-label           ← "Unit N"
        │           └── .unit-tab-title            ← 主题名称
        ├── .video-area
        │     └── <video controls src="...">      ← 活动视频播放器
        └── .card-body
              ├── .hdr                             ← 标题 + 副标题
              ├── .desc                            ← 封面简介（可选）
              ├── .comic-viewport                  ← 漫画视口
              │     ├── .page-indicator            ← 页码指示器（"1 / 6"）
              │     ├── .frame-img                  ← 当前帧图片
              │     └── .bubbles                    ← 对话气泡层
              │           ├── .bubble.left          ← 左侧气泡（蓝色）
              │           ├── .bubble.right         ← 右侧气泡（粉色）
              │           └── .bubble.center        ← 中间气泡（绿色加粗）
              ├── .page-dots                       ← 页面圆点导航
              │     └── .page-dot[data-dot="N"]     ←（.active = 当前页，加长）
              └── .nav                             ← 底部导航按钮
                    ├── .nav-btn[data-nav="prev"]   ← 上一页（首页时禁用）
                    └── .nav-btn.primary[data-nav="next"]  ← 下一页（末页时禁用）
```

---

## 对话气泡规则

| texts 索引 | 渲染位置 | 样式 |
|-----------|---------|------|
| texts[0] | `.bubble.left` | 蓝色，左上角 |
| texts[1] | `.bubble.right` | 粉色，右上角（仅 2 条时移至右下） |
| texts[2+] | `.bubble.center` | 绿色，底部居中，加粗 |

气泡以交错弹出动画（staggered pop）依次出现。

---

## Unit 标签页

- 6 个颜色编码标签（琥珀、蓝、绿、粉、紫、橙）
- 窄屏时可水平滚动
- 点击标签加载对应 Unit（视频 + 面板重置到第 1 页）
- 激活标签使用该 Unit 的品牌色填充背景

---

## 导航交互

| 交互方式 | 行为 |
|---------|------|
| **前后按钮** | 在同一 Unit 内切换面板 |
| **页面圆点** | 点击任意圆点跳转到对应面板；激活圆点加长 |
| **触摸滑动** | 在漫画视口左右滑动切换面板 |
| **键盘** | ← → 方向键切换面板 |
| **滑动过渡** | 翻页时有方向性滑动动画 |

---

## 响应式适配

5 端适配断点（`ai-card.css` 统一管理）：

| 端 | 断点 | 卡片 max-width | 主要变化 |
|----|------|---------------|---------|
| 手机端 | < 480px | 380px | 基准尺寸 |
| 平板端 | ≥ 480px | 440px | 标签字体增大 |
| 大屏端 | ≥ 768px | 520px | 气泡间距增大 |
| 电脑端 | ≥ 1024px | 600px | 视频区增高 |
| 电视端 | ≥ 1440px | 720px | 面板图片最大化 |

---

## 主题配色

- 每个 Unit 拥有独立品牌色（amber / blue / green / pink / purple / orange）
- 切换 Unit 时 CSS 变量（`--c-brand`、`--c-light`、`--c-soft`）同步更新
- 主按钮、激活圆点、激活标签使用当前 Unit 品牌色

---

## 数据概览

| Unit | 主题 | 面板数 | 视频 |
|------|------|--------|------|
| 1 | Pets — Meet My Little Friends | 5 | ✓ |
| 2 | Animals — A Day at the Zoo | 6 | ✓ |
| 3 | Face — We Are Twins! | 6 | ✓ |
| 4 | Body — My Robot Monster | 4 | ✓ |
| 5 | My Home — Tidy Up Time | 6 | ✓ |
| 6 | Time — Happy Birthday, Dad! | 1 | ✓ |

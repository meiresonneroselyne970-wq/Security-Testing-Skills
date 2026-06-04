---
card_type: qa_card
folder: Question and Answer Card
version: "1.0"
---

# 问答卡片 · 完整版 (Question and Answer Card)

可配置的 AI 知识问答卡片模板，支持快捷提问、API 健康检测、知识库来源展示。通过 `data.json` 配置 UI 文案、快捷提示和 API 端点。

---

## 目录

1. [文件结构](#文件结构)
2. [JSON Schema](#json-schema)
3. [字段说明](#字段说明)
4. [HTML 渲染结构](#html-渲染结构)
5. [数据变体](#数据变体)
6. [主题配色](#主题配色)
7. [响应式适配](#响应式适配)
8. [渲染说明](#渲染说明)

---

## 文件结构

```
Question and Answer Card/
├── index.html       # 页面结构（卡片骨架 + 加载 CSS/JS）
├── style.css        # 卡片样式（5 端响应式 + 动画）
├── app.js           # 问答逻辑（API 调用 + 状态管理 + DOM 渲染）
├── data.json        # UI 配置（标题、快捷提示、API 端点、图标映射）
└── metadata.md      # 本文件
```

---

## JSON Schema

```json
{
  "api": {
    "base": "http://127.0.0.1:8899",
    "qa_endpoint": "/qa",
    "health_endpoint": "/health"
  },
  "ui": {
    "title": "炎图 AI 知识问答",
    "subtitle": "基于知识库的智能检索与回答",
    "placeholder": "请输入你的问题…",
    "logo": "🤖",
    "quick_prompts": [
      { "label": "🍱 公司餐补", "question": "公司餐补是多少？" }
    ],
    "category_icons": { "architecture": "🏗️" },
    "file_icons": { "md": "📘" },
    "default_file_icon": "📎",
    "default_category_icon": "📁"
  },
  "request": {
    "top_k": 5,
    "timeout_ms": 30000
  }
}
```

---

## 字段说明

### api

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `api.base` | string | 是 | API 服务基础地址，如 `http://127.0.0.1:8899` |
| `api.qa_endpoint` | string | 是 | 问答接口路径，如 `/qa` |
| `api.health_endpoint` | string | 是 | 健康检测接口路径，如 `/health` |

### ui

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `ui.title` | string | 是 | 卡片标题，显示在 header 中 |
| `ui.subtitle` | string | 否 | 副标题，灰色小字。缺失则隐藏 |
| `ui.placeholder` | string | 否 | 输入框占位文案，默认"请输入你的问题…" |
| `ui.logo` | string | 否 | 卡片 logo emoji/文字，显示在标题上方圆角方块中 |
| `ui.quick_prompts` | array | 否 | 快捷提问按钮列表，每项含 `label` 和 `question` |
| `ui.category_icons` | object | 否 | 分类名 → emoji 图标映射，用于来源分类标签 |
| `ui.file_icons` | object | 否 | 文件扩展名 → emoji 图标映射 |
| `ui.default_file_icon` | string | 否 | 未知文件类型的默认图标，默认 `"📎"` |
| `ui.default_category_icon` | string | 否 | 未知分类的默认图标，默认 `"📁"` |

### request

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `request.top_k` | number | 否 | 知识库检索返回数量，默认 5 |
| `request.timeout_ms` | number | 否 | 请求超时毫秒数，默认 30000 |

---

## HTML 渲染结构

`app.js` 动态生成以下 DOM 树：

```
body
  └── .bg-layer                          ← 背景光晕层（固定定位）
  └── .qa-card#qaCard                    ← 卡片根容器
        ├── .qa-card-header              ← 卡片头部
        │     ├── .qa-logo               ← Logo（紫蓝渐变圆角方块）
        │     ├── h2                     ← 标题
        │     └── .desc                  ← 副标题（可选）
        ├── .qa-card-body#qaBody         ← 卡片主体（可滚动）
        │     ├── [idleState]            ← 空闲状态
        │     │     ├── .state-icon 💡    ← 状态图标
        │     │     ├── .state-text       ← 引导文案
        │     │     └── .state-hint       ← 提示文案
        │     ├── [typing-dots]          ← 加载状态（三个跳动圆点）
        │     ├── [qa-answer]            ← 回答结果
        │     │     ├── .answer-text      ← 回答正文
        │     │     ├── .kc-block         ← 相关分类标签区
        │     │     │     ├── .kc-label
        │     │     │     └── .kc-tags → .kc-tag × N
        │     │     ├── .kc-block         ← 相关文件列表
        │     │     │     ├── .kc-label
        │     │     │     └── .kc-files → .kc-file × N
        │     │     │           ├── .file-icon
        │     │     │           ├── .file-name
        │     │     │           └── .file-type
        │     │     └── [qa-error]        ← 错误块（可选）
        │     └── [qa-state]             ← 空结果状态
        └── .qa-card-footer              ← 卡片底部
              ├── .quick-prompts          ← 快捷提问按钮组
              │     └── .quick-prompt × N
              ├── .input-row              ← 输入行
              │     ├── input#qaInput     ← 文本输入框
              │     └── button.send-btn   ← 发送按钮（➤）
              └── .api-status             ← API 状态栏
                    ├── .dot              ← 状态指示圆点
                    └── span              ← 状态文字
```

### 状态切换

| 状态 | 触发条件 | DOM |
|------|---------|-----|
| 空闲 | 页面加载后，用户未提问 | `#idleState`（💡 + 引导文案） |
| 加载中 | 点击发送/快捷按钮，等待 API 响应 | `.typing-dots`（三个跳动圆点） |
| 回答 | API 返回成功 | `.qa-answer`（回答文本 + 分类 + 文件） |
| 空结果 | API 返回但无有效内容 | `.qa-state`（🤔 + "未找到相关内容"） |
| 错误 | 网络错误 / API 返回 error 字段 | `.qa-error`（⚠️ + 错误信息） |

### 自适应规则

| 字段/条件 | 行为 |
|---------|------|
| `data.json` 加载失败 | 使用 `getDefaultConfig()` 内置默认配置 |
| `ui.quick_prompts` 为空 | 快捷按钮区不渲染 |
| API 健康检查通过 | 状态圆点绿色 + "API 在线" |
| API 健康检查失败 | 状态圆点红色 + "API 离线" |
| `data.error` 存在 | 渲染错误块（⚠️ + 错误详情） |
| `data.description` 或 `data.answer` 存在 | 渲染回答正文 |
| `data.sources` 有内容 | 渲染分类标签 + 文件列表 |
| 文件名为 `[category] name.ext` 格式 | 自动解析出分类和文件扩展名 |

---

## 数据变体

### data.json — 炎图 AI 知识问答
| 属性 | 值 |
|------|-----|
| 标题 | 炎图 AI 知识问答 |
| 副标题 | 基于知识库的智能检索与回答 |
| Logo | 🤖 |
| 快捷提示 | 4 条（公司餐补、员工福利、技术架构、公司项目） |
| top_k | 5 |
| 超时 | 30s |

> 可扩展：修改 `data.json` 中的 `ui.quick_prompts` 可自定义快捷提问列表；修改 `api.base` 指向不同后端。

---

## 主题配色

| 元素 | 颜色 | 说明 |
|------|------|------|
| 主色 `--primary` | #6366f1 | Indigo，按钮、输入框聚焦、链接 |
| 主色浅 `--primary-light` | #eef2ff | 分类/文件块的背景色 |
| 辅助色 `--accent` | #8b5cf6 | 渐变中的紫色 |
| 成功 `--success` | #22c55e | API 在线状态圆点 |
| 危险 `--danger` | #ef4444 | 错误块、API 离线状态 |
| Logo 背景 | linear-gradient(135deg, #6366f1, #8b5cf6) | 紫蓝渐变 |
| 发送按钮 | linear-gradient(135deg, #6366f1, #8b5cf6) | 紫蓝渐变圆形按钮 |
| 背景光晕 | radial-gradient × 3（indigo/紫/蓝，低透明度） | 固定定位装饰 |

---

## 响应式适配

4 端适配断点（`style.css` 中管理）：

| 端 | 断点 | 卡片 max-width | 主要变化 |
|----|------|---------------|---------|
| 手机端 | < 480px | 520px | 减小 padding，body 顶对齐，输入框缩小 |
| 平板端 | ≥ 480px | 520px | 标准布局 |
| 大屏端 | ≥ 768px | 520px | 卡片居中，舒适间距 |
| 电视端 | ≥ 1440px | 520px | 卡片居中，大背景光晕 |

### 缩放策略

- **卡片宽度**：始终 `max-width: 520px`，宽度自适应但不超过此值
- **移动端适配**：`padding` 缩减（header 22→20px, body 16→18px），`padding-top: 40px` 避免贴顶
- **body max-height**：从 420px → 360px（手机端）

---

## 渲染说明

1. **配置驱动**：所有 UI 文案和功能开关通过 `data.json` 控制，加载失败自动回退到内置默认配置
2. **API 健康检测**：页面加载时自动 `GET /health`，通过状态圆点（绿/红）和文字反馈 API 可用性
3. **快捷提问**：`quick_prompts` 渲染为圆角标签按钮，点击自动填入问题并发送
4. **来源解析**：文件名格式 `[category] filename.ext`，自动解析出分类标签和文件类型图标
5. **发送防抖**：`isSending` 标志位防止重复提交，输入框和按钮同步 disabled
6. **CORS 友好**：POST 请求不设 `Content-Type`，避免触发 CORS 预检（OPTIONS）
7. **无 Shadow DOM**：与 Web Component 卡片模板不同，此卡片使用传统 CSS 方式，样式直接作用于全局 DOM
8. **纯前端**：无框架依赖，零构建步骤，可直接在浏览器中打开

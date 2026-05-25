---
name: card
description: Generate AI cards. 3 visual templates (text / homework / media), each in its own folder with CSS + JS + JSON + metadata.
---

# /card — AI 卡片生成器

传入自然语言描述或 JSON 数据，自动判断复用现有模板还是创建新模板，生成卡片文件并更新预览页。

---

## 核心决策：复用 vs 新建

收到一张卡片需求时，按以下流程判断：

```
用户描述/JSON
    │
    ▼
┌─────────────────────────────────┐
│ 1. 提取视觉特征                  │
│    - 有没有暗色媒体预览区？        │
│    - 有没有彩色渐变横幅？          │
│    - 有没有顶部装饰条+左侧色条？   │
│    - 全都不匹配？                 │
└─────────────────────────────────┘
    │
    ├─ 匹配已有模板 ──→ 【复用】添加 JSON 到对应文件夹
    │
    └─ 不匹配任何模板 ──→ 【新建】创建文件夹 + CSS + JS + HTML + MD
```

**关键原则：按视觉布局归类，不按 card_type 字段值归类。** 5 种 card_type（h5_entry、assistant_welcome、recommendation、task、health_advice）共用同一个 text-card 模板，因为它们的 DOM 结构完全一致，只是数据不同。

---

## 3 种现有模板

### 1. text-card — 文本类卡片

**视觉特征：** 顶部 3px 渐变装饰条 + 左侧 4px 品牌色竖条 + 42px 图标 + 标题/副标题/标签 + 描述文字 + 操作按钮

**DOM 骨架：**
```
card
  ├── strip（顶部渐变条）
  └── card-body（::after 左侧色条）
        ├── hdr
        │     ├── icon（42×42 浅色背景）
        │     └── hinfo
        │           ├── title
        │           ├── subtitle（可选）
        │           └── badge（可选，card_type 驱动）
        ├── desc（可选）
        └── actions → button
```

**匹配规则（满足任意一条即命中）：**
- 卡片需要一个带图标的标题行，下面跟描述文字和按钮
- 卡片结构是"头图/图标 + 标题 + 正文 + 按钮"
- 不需要彩色横幅、不需要媒体预览区

**已有变体：** h5_entry、assistant_welcome、recommendation、task、health_advice（共 5 种 card_type，7 个 JSON 文件）

**可用的 card_type：** `h5_entry`、`assistant_welcome`、`recommendation`、`task`、`health_advice`

**可用的 icon：** `ai`、`link`、`sparkle`、`task`、`health`、`audio`（如需新增，在 ICONS 对象加一行）

**可用的 theme：** `blue_white`、`purple_white`、`cyan_white`、`amber_white`、`emerald_white`（如需其他颜色，在 PALETTE 加对应色值）

**badge 映射（在 JS 的 BADGES 对象中）：**
| card_type | badge 文案 |
|-----------|-----------|
| `h5_entry` | H5 入口 |
| `assistant_welcome` | AI 助手 |
| `recommendation` | AI 推荐 |
| `task` | （无） |
| `health_advice` | （无） |

---

### 2. homework-card — 作业提醒卡片

**视觉特征：** 顶部彩色渐变横幅（内含图标 + 标题 + 副标题 + 学科标签）+ 下方描述 + 操作按钮

**DOM 骨架：**
```
card
  ├── bar（彩色渐变横幅，135deg）
  │     ├── bicon（42×42 半透明白底）
  │     └── binfo
  │           ├── btitle（白色加粗）
  │           ├── bsub（可选，85% 透明度）
  │           └── bbadge（可选，theme 驱动学科）
  └── card-body
        ├── desc（可选）
        └── actions → button
```

**匹配规则（满足任意一条即命中）：**
- 需要一个突出的彩色顶部横幅来承载标题
- 横幅颜色有语义含义（如红色=语文、蓝色=数学、绿色=英语）
- 学科/分类信息需要在横幅中醒目展示

**已有变体：** chinese、math、english（共 3 个 JSON 文件）

**theme → 学科映射（在 JS 的 subjectFromTheme 中）：**
| theme | 学科 | icon |
|-------|------|------|
| `red_white` | 语文 | `chinese` |
| `blue_white` | 数学 | `math` |
| `green_white` | 英语 | `english` |

**扩展新学科时**，需在 JS 中同步更新 3 处：
1. `PALETTE` — 新颜色值
2. `subjectFromTheme()` — theme → subject key 映射
3. `subjectLabel()` — subject key → 中文标签映射

---

### 3. media-card — 媒体预览卡片

**视觉特征：** 150px 暗色预览区（#1e1b4b）+ 类型标签（左上角）+ 播放按钮（居中白色圆形）+ 时长标签（右下角）+ 下方图标标题 + 描述 + 操作按钮

**DOM 骨架：**
```
card
  ├── media-area（150px，深紫色背景）
  │     ├── media-badge（"视频"/"音频"/"图片"/"文件"）
  │     ├── media-play（▶ 52×52 白色圆形）
  │     └── media-dur（可选，由 subtitle 字段驱动）
  └── card-body
        ├── hdr
        │     ├── icon（42×42 浅色背景）
        │     └── hinfo → title
        ├── desc（可选）
        └── actions → button
```

**匹配规则（满足任意一条即命中）：**
- 需要预览/缩略图区域（视频封面、音频波形、图片缩略图等）
- 预览区上有叠加的标签/按钮元素
- subtitle 字段用于显示时长而非副标题

**已有变体：** class-video（1 个 JSON 文件）

**可用的 icon：** `video`、`audio`、`image`、`file`（如需新增，在 ICONS 对象加一行）

**特殊行为：** `subtitle` 不显示为副标题，而是作为时长标签渲染在预览区右下角

---

## 复用流程（匹配到已有模板）

当卡片匹配到上述 3 种模板之一时：

### Step 1：确定文件夹

根据视觉特征选择 `text-card/`、`homework-card/` 或 `media-card/`。

### Step 2：创建 JSON 文件

严格按照以下 schema，**不添加文档之外的扩展字段**：

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "...",
  "subtitle": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "https://...",
  "theme": "..._white",
  "layout": {
    "variant": "...",
    "icon": "..."
  }
}
```

- `card_type` 和 `layout.variant` 保持一致
- `layout.icon` 从该模板支持的 icon 列表中选择
- `theme` 从该模板的 PALETTE 中选择
- JSON 字符串内的引号用「」代替 ASCII 引号，避免解析冲突
- 文件名用 kebab-case

### Step 3：更新 index.html

在对应文件夹的 `index.html` 中，找到 `var CARDS = [` 数组，追加一条：

```javascript
{file:"新文件名.json", data:{/* 完整的 JSON 数据 */}},
```

### Step 4：更新 ai-card-demo.html

在根目录 `ai-card-demo.html` 的 `CARDS` 数组中追加：

```javascript
{folder:'模板文件夹名', group:'分组标签', file:'新文件名.json', data:{/* 完整的 JSON 数据 */}},
```

`group` 字段用于 demo 页的分组标题，与已有同组卡片保持一致。

### Step 5：如需新 icon/颜色

如果新卡片用到了该模板尚未支持的 icon 或 theme 颜色：

- **新 icon**：在 JS 的 `ICONS` 对象中添加一行
- **新颜色**：在 JS 的 `PALETTE` 对象中添加色值（brand、light、soft、gradStart、gradEnd）
- **新 badge**：在 `BADGES` 对象中添加 card_type → 文案映射（仅 text-card）
- **新学科**：更新 `subjectFromTheme()` 和 `subjectLabel()`（仅 homework-card）

### Step 6：验证

用浏览器打开对应文件夹的 `index.html` 和根目录的 `ai-card-demo.html`，确认卡片渲染正常。

---

## 新建模板流程（不匹配任何现有模板）

当卡片的视觉布局与 3 种现有模板**都不同**时，创建新模板文件夹。

### 判断标准：以下情况需要新建

- 布局结构完全不同（如：卡片是横排的、有多列、有底部固定栏等）
- 需要新的 DOM 元素类型（如：进度条、头像组、评分星级、标签组等）
- 现有的 CSS 无法通过修改变量覆盖，需要全新的样式体系
- 字段有特殊语义（如 media-card 中 subtitle 用作时长标签）

### 新建文件夹的步骤

**1. 创建文件夹**，命名为 `{特征}-card`（kebab-case），如 `poll-card`、`calendar-card`。

**2. 创建 `ai-card.css`**，骨架：

```css
/* {name}-card/ai-card.css */

:host {
  display: block;
  max-width: 380px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif;
  --c-brand: #3b82f6;
  --c-light: #eff6ff;
  --c-soft: #dbeafe;
  --c-grad-start: #3b82f6;
  --c-grad-end: #60a5fa;
}

.card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,.06), 0 1px 2px rgba(0,0,0,.04);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* 在此添加该模板特有的样式类 */
/* 共享的 .desc、.actions、.btn 可从现有模板复制 */
```

**3. 创建 `ai-card.js`**，骨架：

```javascript
/**
 * {name}-card/ai-card.js — {中文说明}
 * 模板：{一句话描述视觉结构}
 */
const BASE = document.currentScript
  ? new URL('.', document.currentScript.src).href
  : location.href;

const PALETTE = {
  // 只放该模板需要的颜色
  blue: { brand:'#3b82f6', light:'#eff6ff', soft:'#dbeafe', gradStart:'#3b82f6', gradEnd:'#60a5fa' },
};

function themeColor(t) { const n=(t||'blue_white').split('_')[0]; return PALETTE[n]||PALETTE.blue; }

const ICONS = {
  // 该模板支持的 icon → emoji 映射
};

function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'default'; return ICONS[i]||'🔗'; }

class AICard extends HTMLElement {
  constructor() { super(); this.attachShadow({ mode:'open' }); }
  static get observedAttributes() { return ['data']; }
  attributeChangedCallback() { this.render(); }
  connectedCallback() { this.render(); }

  render() {
    const raw = this.getAttribute('data');
    if (!raw) { this.shadowRoot.innerHTML=''; return; }
    let d; try { d=JSON.parse(raw); } catch { this.shadowRoot.innerHTML=''; return; }
    const p = themeColor(d.theme);
    this.shadowRoot.innerHTML='';

    const link = document.createElement('link');
    link.rel='stylesheet'; link.href=new URL('./ai-card.css', BASE).href;
    this.shadowRoot.appendChild(link);

    const vars = document.createElement('style');
    vars.textContent = `:host{--c-brand:${p.brand};--c-light:${p.light};--c-soft:${p.soft};--c-grad-start:${p.gradStart};--c-grad-end:${p.gradEnd}}`;
    this.shadowRoot.appendChild(vars);

    const wrapper = document.createElement('div');
    wrapper.innerHTML = cardHTML(d);
    this.shadowRoot.appendChild(wrapper.firstElementChild);
  }
}

function cardHTML(d) {
  const icon = iconEmoji(d);
  const btn = d.button_text || '默认按钮文案';
  return `
<div class="card">
  <!-- 在此构建该模板特有的 DOM 结构 -->
  <!-- 可选字段用三元表达式：${d.subtitle?`<div>...</div>`:''} -->
  <div class="card-body">
    ${d.description?`<div class="desc">${esc(d.description)}</div>`:''}
    <div class="actions"><button class="btn primary">${esc(btn)}</button></div>
  </div>
</div>`;
}

function esc(s) { if(s==null)return''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

if (!customElements.get('ai-card')) customElements.define('ai-card', AICard);

// ── 卡片列表渲染 ──
(function(){
  if (typeof CARDS==='undefined') return;
  var root=document.getElementById('root');
  if (!root) return;
  root.innerHTML=CARDS.map(function(c){
    return '<div class="wrap"><span class="label">'+c.file+' · '+c.data.theme+' · icon='+c.data.layout.icon+'</span><ai-card data=\''+JSON.stringify(c.data)+'\'></ai-card></div>';
  }).join('');
})();
```

**4. 创建 `index.html`**，骨架：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>{中文名称} — {folder-name}</title>
<link rel="stylesheet" href="ai-card.css">
<style>
*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif;background:#f0f2f5;padding:24px;display:flex;flex-direction:column;align-items:center;gap:20px}h1{font-size:18px;font-weight:700;color:#111827}.sub{font-size:12px;color:#9ca3af;text-align:center}.wrap{display:flex;flex-direction:column;gap:6px;max-width:400px;width:100%}.label{font-size:10px;color:#9ca3af;text-transform:uppercase;letter-spacing:.5px;padding-left:4px}
</style></head>
<body>
<h1>{中文名称}</h1><p class="sub">{一句话描述}</p>
<div id="root"></div>
<script>
var CARDS = [
  {file:"第一个.json", data:{/* JSON 数据 */}},
];
</script>
<script src="ai-card.js"></script>
</body></html>
```

**5. 创建至少一个 JSON 数据文件。**

**6. 创建 `metadata.md`**，包含：文件结构、JSON Schema、字段说明、HTML 渲染结构（DOM 树）、自适应规则、数据变体、主题配色、渲染说明。

**7. 更新 `ai-card-demo.html`**：
- 在 `<body>` 底部添加新的 `<script src="{folder}/ai-card.js"></script>`（放在其他 script 标签之后）
- 在 `CARDS` 数组中追加新卡片的条目

**8. 更新本 skill 文件**，在"3 种现有模板"后增加第 4 种模板的说明。

---

## JSON Schema（所有卡片通用）

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "...",
  "subtitle": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "https://...",
  "theme": "..._white",
  "layout": {
    "variant": "...",
    "icon": "..."
  }
}
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `schema_version` | 是 | 固定 `"1.0"` |
| `card_type` | 是 | 与 `layout.variant` 一致 |
| `title` | 是 | 卡片主标题 |
| `subtitle` | 否 | 缺失则隐藏（media-card 中用作时长） |
| `description` | 否 | 缺失则隐藏 |
| `button_text` | 否 | 缺失则使用模板默认文案 |
| `target_url` | 是 | 按钮跳转地址 |
| `theme` | 否 | 格式 `{color}_white`，默认由模板决定 |
| `layout.variant` | 否 | 与 `card_type` 一致 |
| `layout.icon` | 否 | 控制图标，从模板 ICONS 中选择 |

---

## 颜色方案

| theme | 品牌色 | 适用模板 | 典型场景 |
|-------|--------|---------|---------|
| `blue_white` | #3b82f6 | text, homework | 通用入口、数学 |
| `purple_white` | #8b5cf6 | text | AI 助手 |
| `cyan_white` | #0891b2 | text | 内容推荐 |
| `amber_white` | #d97706 | text | 任务协作 |
| `emerald_white` | #059669 | text | 健康医疗 |
| `red_white` | #dc2626 | homework | 语文学科 |
| `green_white` | #16a34a | homework | 英语学科 |
| `indigo_white` | #4f46e5 | media | 媒体预览 |

---

## 响应式适配（5 端）

所有模板 CSS 和 index.html 必须适配 5 种设备端：

| 端 | 断点 | 卡片 max-width | 页面布局 |
|----|------|---------------|---------|
| 手机端 | 默认（< 480px） | 380px | 单列居中 |
| 平板端 | `≥ 480px` | 420px | 单列居中 |
| 大屏端 | `≥ 768px` | 460px | 双列网格 |
| 电脑端 | `≥ 1024px` | 500px | 双列/三列 |
| 电视端 | `≥ 1440px` | 560px | 三列/四列（demo 页） |

### CSS 适配要点

- 卡片宽度、字体、图标、间距、圆角全部渐进缩放（每档约 +10%）
- 按钮 padding 随屏幕增大，确保电视端远距离可点击
- 页面容器（`#root`）在大屏以上切换为 CSS Grid
- index.html 和 demo 页的响应式布局写在 `<style>` 标签的媒体查询中

### 新建模板时的响应式 checklist

- [ ] `ai-card.css` 包含 4 个媒体查询断点（480/768/1024/1440）
- [ ] 所有尺寸属性（width/height/font-size/padding/gap/border-radius）都被覆盖
- [ ] `index.html` 的 `#root` 在大屏上切换为 grid 布局
- [ ] demo 页的 `.grid` 容器适配对应断点

---

## 注意事项

1. **按视觉布局归类**：不要被 card_type 字段名误导，5 种 card_type 共用 text-card 模板因为它们的 DOM 结构一样
2. **JSON 不含扩展字段**：严格遵守文档 schema，不添加 `subject`、`teacher`、`submit_count` 等自造字段
3. **引号处理**：JSON 字符串内的中文引号用「」代替 ASCII 引号，避免解析冲突
4. **命名规范**：JSON 文件名用 kebab-case，按用途命名（如 `oral-practice.json`）
5. **JS 精简**：每个文件夹的 `ai-card.js` 只包含当前模板需要的 PALETTE 颜色和渲染函数，不含死代码
6. **CSS 精简**：每个文件夹的 `ai-card.css` 只包含当前模板用到的样式类
7. **自定义元素守卫**：`customElements.define` 前加 `customElements.get('ai-card')` 检查，兼容 demo 页同时加载多个 JS
8. **同步更新**：新增卡片或模板后，必须同步更新 demo 页和本 skill 文件
9. **metadata.md**：每个模板文件夹必须有完整的 metadata.md（目录、schema、字段表、DOM 树、自适应规则、变体表、配色表、响应式表、渲染说明）
10. **5 端适配**：所有 CSS 和页面布局必须覆盖手机/平板/大屏/电脑/电视 5 个断点

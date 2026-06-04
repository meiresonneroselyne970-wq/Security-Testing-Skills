---
name: card
description: Generate AI cards. 6 card templates (text / homework / media / english-word / comic / answer), each in its own folder with CSS + JS + JSON + metadata.
---

# /card — AI Card Generator

Accepts natural language descriptions or JSON data. Automatically decides whether to reuse an existing template or create a new one. Generates card files and updates preview pages.

---

## Core Decision: Reuse vs. New Template

When receiving a card request, follow this decision flow:

```
User description / JSON
    │
    ▼
┌─────────────────────────────────────────────┐
│ 1. Extract visual features                   │
│    - Has a dark media preview area?           │
│    - Has a colored gradient banner?           │
│    - Has a top accent strip + left bar?       │
│    - Has notebook paper + tape + ribbon?      │
│    - Has video player + paginated panels?     │
│    - Has Q&A input + API response display?    │
│    - None of the above?                       │
└─────────────────────────────────────────────┘
    │
    ├─ Matches existing template ──→ [REUSE] Add JSON to the matching folder
    │
    └─ No match ──→ [NEW] Create folder + CSS + JS + HTML + MD
```

**Key principle: group by visual layout, not by card_type field value.** Five card_types (h5_entry, assistant_welcome, recommendation, task, health_advice) share the same text-card template because their DOM structure is identical — only the data differs.

---

## Architecture Overview: Two Card Families

This project has **two architectural families** of card templates:

| Family | Pattern | Rendering | Shared Engine | Examples |
|--------|---------|-----------|---------------|----------|
| **Web Component** | `<ai-card>` custom element + Shadow DOM | `ai-card.js` reads `data` attribute → renders to Shadow DOM | `ai-card.css` scoped inside Shadow DOM | text, homework, media, english-word, comic |
| **Standalone** | Plain HTML + CSS + vanilla JS | `app.js` directly manipulates DOM | CSS classes on global document | answer (精简版) |

**Why two families?** The Answer card is a full interactive application (user input → API call → dynamic rendering), not a static data-driven display card. It pre-dates the Web Component pattern and follows a more traditional SPA architecture.

When the user asks for a card, first determine which **family** it belongs to, then match within that family.

---

## 6 Existing Templates

### 1. text-card — Text Content Cards

**Visual signature:** 3px gradient accent strip at top + 4px brand-color left bar (::after pseudo-element) + 42px icon + title/subtitle/badge + description + action button.

**DOM skeleton:**
```
card
  ├── strip (top gradient bar)
  └── card-body (::after left color bar)
        ├── hdr
        │     ├── icon (42×42, light bg)
        │     └── hinfo
        │           ├── title
        │           ├── subtitle (optional)
        │           └── badge (optional, driven by card_type)
        ├── desc (optional)
        └── actions → button
```

**Matching rules (any one match is sufficient):**
- Card needs an icon + title row, followed by description text and a button
- Card structure is "icon/header-image + title + body + button"
- No colored banner needed, no media preview area needed

**Existing variants:** h5_entry, assistant_welcome, recommendation, task, health_advice (5 card_types, 7 JSON files)

**Supported card_type values:** `h5_entry`, `assistant_welcome`, `recommendation`, `task`, `health_advice`

**Supported icon values:** `ai`, `link`, `sparkle`, `task`, `health`, `audio` (to add a new one, append to the ICONS object)

**Supported theme values:** `general`, `ai`, `recommendation`, `task`, `health` — mapped to colors via THEME_MAP (to add a new theme, append to THEME_MAP and PALETTE)

**Badge mapping (in JS BADGES object):**
| card_type | badge text |
|-----------|-----------|
| `h5_entry` | H5 入口 |
| `assistant_welcome` | AI 助手 |
| `recommendation` | AI 推荐 |
| `task` | (none) |
| `health_advice` | (none) |

---

### 2. homework-card — Homework Reminder Cards

**Visual signature:** Colored gradient banner at top (contains icon + title + subtitle + subject badge) + description below + action button.

**DOM skeleton:**
```
card
  ├── bar (colored gradient banner, 135deg)
  │     ├── bicon (42×42, semi-transparent white bg)
  │     └── binfo
  │           ├── btitle (white, bold)
  │           ├── bsub (optional, 85% opacity)
  │           └── bbadge (optional, driven by theme)
  └── card-body
        ├── desc (optional)
        └── actions → button
```

**Matching rules (any one match is sufficient):**
- Needs a prominent colored top banner to display the title
- Banner color has semantic meaning (e.g. red = Chinese, blue = Math, green = English)
- Subject/category info must be prominently displayed inside the banner

**Existing variants:** chinese, math, english (3 JSON files)

**theme → subject mapping (theme IS the subject, THEME_MAP resolves the color):**
| theme | subject | color |
|-------|--------|-------|
| `chinese` | 语文 (Chinese) | red |
| `math` | 数学 (Math) | blue |
| `english` | 英语 (English) | green |

**When adding a new subject**, update 3 places in JS:
1. `PALETTE` — add new color values
2. `THEME_MAP` — add theme → color mapping
3. `SUBJECT_LABEL` — add theme → display label mapping

---

### 3. media-card — Media Preview Cards

**Visual signature:** 150px dark preview area (#1e1b4b) + type badge (top-left) + play button (centered white circle) + duration label (bottom-right) + icon + title below + description + action button.

**DOM skeleton:**
```
card
  ├── media-area (150px, dark purple bg)
  │     ├── media-badge ("Video" / "Audio" / "Image" / "File")
  │     ├── media-play (▶ 52×52 white circle)
  │     └── media-dur (optional, driven by subtitle field)
  └── card-body
        ├── hdr
        │     ├── icon (42×42, light bg)
        │     └── hinfo → title
        ├── desc (optional)
        └── actions → button
```

**Matching rules (any one match is sufficient):**
- Needs a preview/thumbnail area (video cover, audio waveform, image thumbnail, etc.)
- Preview area has overlaid labels/button elements
- subtitle field is used to display duration rather than a subtitle text

**Existing variants:** class-video (1 JSON file)

**Supported icon values:** `video`, `audio`, `image`, `file` (to add a new one, append to the ICONS object)

**Special behavior:** `subtitle` is NOT displayed as a subtitle text — it renders as a duration label in the bottom-right corner of the preview area.

---

### 4. english-word-card — English Word Learning Cards

**Visual signature:** Notebook paper background (横线纸) + semi-transparent sticky note with tape decoration at top + purple ribbon badge (缎带) tilted at top-left + big letter display (Aa) on left + word label + real-object image on right + interactive click-to-speak (Web Speech API).

**DOM skeleton:**
```
card (abc-card, semi-transparent white, rounded, shadow)
  ├── tape-decor (centered at top, dotted border)
  ├── abc-ribbon (purple, tilted -2deg, top-left)
  └── abc-body
        ├── abc-row (horizontal flex)
        │     ├── abc-left → big-letter
        │     │     ├── letter-upper (60px, bold, text-shadow)
        │     │     └── letter-lower (40px, bold)
        │     └── abc-right
        │           ├── word-label (32px, bold)
        │           └── abc-img (80×80, drop-shadow)
        └── actions → button
```

**Matching rules (any one match is sufficient):**
- Needs a notebook/school-supply visual feel (paper background, tape, ribbon)
- Big letter display for language/alphabet learning
- Click-to-speak pronunciation interaction
- Image-based word association for children's education

**Existing variants:** a-for-apple (1 JSON file: `data.json`)

**Supported card_type values:** `english_word`

**Supported icon values:** `abc` (to add a new one, append to the ICONS object)

**Supported theme values:** `abc` — mapped to purple via THEME_MAP (to add a new theme, append to THEME_MAP and PALETTE)

**Special behavior:**
- `subtitle` is the letter pair (e.g. "Aa"), rendered as big letter — NOT as subtitle text. First char = uppercase, rest = lowercase.
- `description` is the English word (e.g. "apple"), rendered as word label and used as image alt text.
- `title` is the ribbon badge text.
- Page-level notebook paper background (`.page-container`) only appears in standalone `index.html`, not in demo/preview cards.
- Web Speech API for pronunciation on click — `data-speak` attributes on `.big-letter`, `.word-label`, and `.abc-img` elements.
- Uses Google Fonts "Patrick Hand" for handwritten textbook feel.

**Google Fonts requirement:** `index.html` `<head>` must include:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Patrick+Hand&display=swap" rel="stylesheet">
```

---

### 5. comic-card — Comic Strip Cards (Paginated)

**Visual signature:** `<video>` player at top (with controls) + single comic frame (image + speech bubbles) + prev/next page navigation with page indicator.

**DOM skeleton:**
```
comic-card
  ├── video-area
  │     └── <video controls src="...">
  └── card-body
        ├── hdr (title + subtitle)
        ├── desc (description)
        ├── comic-viewport (single frame per page)
        │     ├── page-indicator ("1 / 6")
        │     ├── frame-img (single image, rounded)
        │     └── bubbles
        │           ├── bubble.left (blue, left-aligned)
        │           ├── bubble.right (pink, right-aligned)
        │           └── bubble.center (green, centered, bold)
        └── nav
              ├── nav-btn[data-nav="prev"] ← 上一页
              └── nav-btn.primary[data-nav="next"] 下一页 →
```

**Matching rules (any one match is sufficient):**
- Has a video at the top and image+text panels with page-by-page navigation
- Comic/manga style sequential storytelling, one panel per page
- Prev/next buttons to flip through 4-6 frames

**Existing variants:** we-are-twins (1 JSON file: `data.json`)

**Supported card_type values:** `comic_strip`

**Supported icon values:** `comic` (to add a new one, append to the ICONS object)

**Supported theme values:** `comic` — mapped to amber (#f59e0b) via THEME_MAP

**Frame structure:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image` | string | Yes | Frame character/scene image URL |
| `texts` | string[] | Yes | Dialogue texts, rendered as alternating bubbles |

**Bubble rules:**
- texts[0] → `.bubble.left` (blue, left-aligned)
- texts[1] → `.bubble.right` (pink, right-aligned)
- texts[2+] → `.bubble.center` (green, centered, bold)

**Special fields (not in standard schema):**
| Field | Required | Description |
|-------|----------|-------------|
| `video_url` | Yes | Video source for `<video controls>` |
| `frames` | Yes | Array of `{ image, texts[] }` objects (4-6 frames) |

For full comic-card documentation, see `.claude/skills/comic.md`.

---

### 6. answer-card (Answer Card) — AI 知识问答卡片·精简版

**Visual signature:** Top shimmer gradient bar (3px, 5-color, animated) + AI avatar header ("AI 回答" + green "● 基于知识库" badge) + gradient-background answer text with left color bar + color-coded file source list. Input row is OUTSIDE the card, as a separate element.

**Architecture:** Standalone (not Web Component). Plain HTML skeleton + `style.css` + `app.js`. All configuration is **hardcoded** in `app.js` — no external config file.

**Folder:** `answer-card/`

**DOM skeleton:**
```
body
  └── .qa-card (::before = shimmer gradient bar, 4s loop animation)
        └── .qa-card-body (scrollable, max-height 500px)
              └── [dynamic content — one of 5 states]
                    ├── #idleState → 💡 (80×80 gradient rounded square) + guide text
                    ├── .typing-dots → 3 bouncing dots (10px, larger)
                    ├── .qa-answer
                    │     ├── .answer-header
                    │     │     ├── .answer-avatar "AI" (32×32 gradient square)
                    │     │     └── .answer-meta
                    │     │           ├── .answer-label "AI 回答"
                    │     │           └── .answer-badge "● 基于知识库" (green)
                    │     ├── .answer-text (gradient bg + left 3px gradient bar)
                    │     └── .sources-block
                    │           ├── .sources-header
                    │           │     ├── .sources-label 📂 "参考来源"
                    │           │     └── .sources-count "N 个文件"
                    │           └── .source-file × N
                    │                 ├── .file-icon-wrap.type-{ext} (6 color variants)
                    │                 ├── .file-info
                    │                 │     ├── .file-name
                    │                 │     └── .file-category (optional)
                    │                 └── .file-type-tag.tag-{ext} (6 color variants)
                    ├── .qa-state → 🤔 "未找到相关内容"
                    └── .qa-error → ⚠️ (pink bg + red border)
  └── .input-row#qaFooter (OUTSIDE card, separate element)
        ├── input#qaInput (standalone shadow, focus glow ring)
        └── button.send-btn (gradient circle, hover scale 1.07)
```

**Matching rules (any one match is sufficient):**
- User needs an answer-only display card (no branding header needed)
- Card should be embeddable in an existing page (input is separate from card)
- Needs richer visual answer styling (AI avatar, gradient text box, color-coded file types)
- Doesn't need quick prompts or health monitoring
- Configuration can be hardcoded (no external config dependency)

**Existing variants:** 1 (炎图 AI 知识问答·精简版, no config file)

**Supported card_type values:** `qa_answer`

**API contract:**
- `POST /qa` ← `{ "question": "...", "top_k": 5 }` → `{ "description": "...", "sources": ["[cat] file.ext"], "error": "" }`
- File name format: `[category] filename.ext` — auto-parsed for category tags and file type icons

**File type color system (`FILE_META` in `app.js`):**
| Extension | Icon | Background | Badge Color |
|-----------|------|-----------|-------------|
| `md` | 📘 | #eef2ff (blue) | #4f46e5 |
| `docx`/`doc` | 📄 | #e0f2fe (sky) | #0369a1 |
| `pptx`/`ppt` | 📊 | #fef3c7 (yellow) | #a16207 |
| `pdf` | 📕 | #fee2e2 (red) | #b91c1c |
| `xlsx`/`xls` | 📈 | #dcfce7 (green) | #15803d |
| `txt` | 📝 | #f3f4f6 (gray) | #4b5563 |
| other | 📎 | #f3f4f6 (gray) | #6b7280 |

**Files:**
| File | Purpose |
|------|---------|
| `index.html` | Static skeleton (card + external input row) |
| `style.css` | All styles, 6 file-type color variants, shimmer animation |
| `app.js` | Hardcoded config, ask(), renderAnswer(), parseFileName() |
| `metadata.md` | Full documentation |

**When to reuse:** Answer-only display card, embeddable widget, richer visual styling needed.

**When to create new:** If a branded header, quick prompts, and health monitoring are needed together with Q&A input — consider extending this template or creating a new one.

---

## Reuse Flow (Template Matched)

When the card matches one of the 6 existing templates:

### Step 1: Choose the Folder

Pick the folder based on visual features:

| Visual Signature | Folder |
|-----------------|--------|
| Icon + title + description + button, top accent strip + left bar | `text-card/` |
| Colored gradient banner (icon + title + subject badge), description below | `homework-card/` |
| Dark 150px preview area, play button, duration label, icon + title below | `media-card/` |
| Notebook paper, tape + ribbon, big letter + word + image, click-to-speak | `english-word-card/` |
| Video player, paginated panels with speech bubbles, prev/next nav | `comic-card/` |
| Answer-only card, AI avatar, gradient text box, color-coded files, external input | `answer-card/` |

### Step 2: Choose the Architecture

- **Web Component family** (text/homework/media/english-word/comic): Follow the JSON + JS IIFE flow below
- **Standalone family** (answer): This has its own `app.js` pattern — modify the existing `app.js` directly or use it as-is; it doesn't use the `ai-card.js` / `ai-card.css` shared engine

### Step 3: Create the JSON File (Web Component family only)

Follow the schema strictly. **Do not add fields outside the spec:**

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "...",
  "subtitle": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "https://...",
  "theme": "general",
  "layout": {
    "variant": "...",
    "icon": "..."
  }
}
```

- `card_type` and `layout.variant` must be the same value
- `layout.icon` must be chosen from the template's supported icon list
- `theme` must be chosen from the template's THEME_MAP (semantic name → color)
- Use 「」for inner quotes inside JSON strings to avoid parser conflicts
- File name in kebab-case

### Step 4: Update the JS auto-fetch list (Web Component family only)

In the template folder's `ai-card.js`, find the IIFE at the bottom and add the new JSON filename to the `FILES` array:

```javascript
var FILES = ['existing.json', 'new-file.json'];
```

### Step 5: Update ai-card-demo.html

In the root `ai-card-demo.html`, append to the `CARDS` array:

```javascript
{folder:'template-folder', group:'Group Label', file:'new-file.json', data:{/* complete JSON data */}},
```

The `group` field controls the section header in the demo page — keep it consistent with existing cards in the same group.

### Step 6: Add New Icon / Color (If Needed)

If the new card uses an icon or theme color not yet supported by the template:

- **New icon:** add one entry to the `ICONS` object in JS
- **New color:** add one entry to the `PALETTE` object (brand, light, soft, gradStart, gradEnd)
- **New badge:** add card_type → label mapping to `BADGES` object (text-card only)
- **New subject:** update `THEME_MAP` and `SUBJECT_LABEL` (homework-card only)

### Step 7: Validate

Open the template folder's `index.html` and the root `ai-card-demo.html` in a browser. Confirm cards render correctly at multiple viewport widths.

---

## New Template Flow (No Existing Match)

When the card's visual layout is **fundamentally different** from all 6 existing templates, create a new template folder.

### When to Create a New Template

- Layout structure is entirely different (e.g. horizontal cards, multi-column, fixed bottom bar)
- Requires new DOM element types (e.g. progress bar, avatar group, star rating, tag group)
- Existing CSS cannot cover the needs through variable overrides — a new style system is required
- Fields carry special semantics not covered by existing templates (like subtitle used as duration in media-card)

### Steps to Create a New Template

**1. Create folder**, named `{feature}-card` (kebab-case), e.g. `poll-card`, `calendar-card`.

**2. Create `ai-card.css`** — skeleton with responsive breakpoints:

```css
/* {name}-card/ai-card.css — {one-line description} */

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

/* Template-specific styles here */
/* Shared .desc, .actions, .btn can be copied from existing templates */

/* ── Tablet 480px+ ── */
@media (min-width: 480px) {
  :host { max-width: 420px; }
  .card { border-radius: 18px; }
}

/* ── Large screen 768px+ ── */
@media (min-width: 768px) {
  :host { max-width: 460px; }
  .card { border-radius: 20px; }
}

/* ── Desktop 1024px+ ── */
@media (min-width: 1024px) {
  :host { max-width: 500px; }
  .card { border-radius: 22px; }
}

/* ── TV 1440px+ ── */
@media (min-width: 1440px) {
  :host { max-width: 560px; }
  .card { border-radius: 24px; }
}
```

**3. Create `ai-card.js`** — skeleton:

```javascript
/**
 * {name}-card/ai-card.js — {brief description}
 * Template: {one-line visual structure summary}
 */
const PALETTE = {
  // Only colors needed by this template
  blue: { brand:'#3b82f6', light:'#eff6ff', soft:'#dbeafe', gradStart:'#3b82f6', gradEnd:'#60a5fa' },
};

var THEME_MAP = {
  // Only mappings needed by this template — semantic name → color key
  general: 'blue',
};

function themeColor(t) { var c = THEME_MAP[t||'general'] || 'blue'; return PALETTE[c] || PALETTE.blue; }

const ICONS = {
  // icon key → emoji mappings for this template
};

function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'default'; return ICONS[i]||'🔗'; }

class AICard extends HTMLElement {
  constructor() { super(); this.attachShadow({ mode:'open' }); this._connected = false; }
  static get observedAttributes() { return ['data']; }
  attributeChangedCallback() { if (this._connected) this.render(); }
  connectedCallback() { this._connected = true; this.render(); }

  render() {
    const raw = this.getAttribute('data');
    if (!raw) { this.shadowRoot.innerHTML=''; return; }
    let d; try { d=JSON.parse(raw); } catch { this.shadowRoot.innerHTML=''; return; }
    const p = themeColor(d.theme);
    this.shadowRoot.innerHTML='';

    const link = document.createElement('link');
    link.rel='stylesheet'; link.href='ai-card.css';
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
  const btn = d.button_text || 'Default Button';
  return `
<div class="card">
  <!-- Build template-specific DOM structure here -->
  <!-- Optional fields use ternary: ${d.subtitle?`<div>...</div>`:''} -->
  <div class="card-body">
    ${d.description?`<div class="desc">${esc(d.description)}</div>`:''}
    <div class="actions"><button class="btn primary">${esc(btn)}</button></div>
  </div>
</div>`;
}

function esc(s) { if(s==null)return''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

if (!customElements.get('ai-card')) customElements.define('ai-card', AICard);

window.renderCards = function(containerId, cards) {
  var root = document.getElementById(containerId);
  if (!root) return;
  root.innerHTML = cards.map(function(c) {
    var d = c.data;
    return '<div class="wrap"><span class="label">'+(d.layout&&d.layout.variant||d.card_type)+' · '+d.theme+' · icon='+(d.layout&&d.layout.icon)+'</span><ai-card data=\''+JSON.stringify(d)+'\'></ai-card></div>';
  }).join('');
};

// ── Auto-fetch and render when loaded in this folder's index.html ──
(function() {
  var root = document.getElementById('root');
  if (!root) return;
  var FILES = ['first.json'];
  Promise.all(FILES.map(function(f) { return fetch(f).then(function(r) { return r.json(); }); }))
    .then(function(data) { renderCards('root', data.map(function(d) { return { data:d }; })); });
})();
```

**4. Create `index.html`** — skeleton with responsive layout:

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>{Display Name} — {folder-name}</title>
<link rel="stylesheet" href="ai-card.css">
</head>
<body>
<div id="root"></div>
<script src="ai-card.js"></script>
</body></html>
```

Page-level styles (body, h1, .sub, #root, .wrap, .label + responsive media queries) live in `ai-card.css` at the bottom, after all component styles. No `<style>` or inline `<script>` blocks in the HTML — the JS auto-fetches its JSON files.

**5. Create at least one JSON data file.**

**6. Create `metadata.md`** — must include: file structure, JSON Schema, field table, HTML render structure (DOM tree), adaptive rules, data variants, theme/palette table, responsive breakpoints table, rendering notes.

**7. Update `ai-card-demo.html`:**
- Add the new template's HTML function, THEME_MAP entries, ICONS, and CSS path to the unified inline Web Component
- Append new card entries to the `CARDS` array

**8. Update this skill file** — add the new template as a 4th entry under "Existing Templates."

---

## JSON Schema (All Cards)

```json
{
  "schema_version": "1.0",
  "card_type": "...",
  "title": "...",
  "subtitle": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "https://...",
  "theme": "general",
  "layout": {
    "variant": "...",
    "icon": "..."
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `schema_version` | Yes | Fixed `"1.0"` |
| `card_type` | Yes | Must match `layout.variant` |
| `title` | Yes | Card main title |
| `subtitle` | No | Hidden if absent (used as duration label in media-card) |
| `description` | No | Hidden if absent |
| `button_text` | No | Falls back to template default if absent |
| `target_url` | Yes | Button target URL |
| `theme` | No | Semantic name (e.g. `general`, `chinese`, `video`), mapped to color via THEME_MAP |
| `layout.variant` | No | Must match `card_type` |
| `layout.icon` | No | Controls icon, choose from template's ICONS |

---

## Theme → Color Mapping

All templates use semantic theme names that map to visual colors via `THEME_MAP`:

| theme | Color | Used By | Typical Use |
|-------|-------|---------|-------------|
| `general` | #3b82f6 (blue) | text | General entry |
| `ai` | #8b5cf6 (purple) | text | AI Assistant |
| `recommendation` | #0891b2 (cyan) | text | Recommendations |
| `task` | #d97706 (amber) | text | Task collaboration |
| `health` | #059669 (emerald) | text | Health & medical |
| `chinese` | #dc2626 (red) | homework | Chinese subject |
| `math` | #3b82f6 (blue) | homework | Math subject |
| `english` | #16a34a (green) | homework | English subject |
| `video` | #4f46e5 (indigo) | media | Video preview |
| `audio` | #4f46e5 (indigo) | media | Audio preview |
| `image` | #4f46e5 (indigo) | media | Image preview |
| `file` | #4f46e5 (indigo) | media | File download |
| `abc` | #8e44ad (purple) | english-word | Alphabet learning |
| `comic` | #f59e0b (amber) | comic | Comic strip / dialogue |
| `answer` | #5b5fe3 (indigo) | answer | AI answer display |

---

## Responsive Design (5 Device Targets)

All template CSS and index.html must adapt to 5 device targets:

| Device | Breakpoint | Card max-width (Web Component) | Card max-width (Answer Card) | Page Layout |
|--------|-----------|-------------------------------|------------------------------|-------------|
| Phone | default (< 480px) | 380px | 600px | Single column, centered |
| Tablet | `≥ 480px` | 420px | 600px | Single column, centered |
| Large screen | `≥ 768px` | 460px | 600px | 2-column grid |
| Desktop | `≥ 1024px` | 500px | 600px | 2 or 3 columns |
| TV | `≥ 1440px` | 560px | 600px | 3 or 4 columns (demo page) |

### CSS Adaptation Guidelines

- Card width, fonts, icons, spacing, and border-radius all scale progressively (~+10% per breakpoint)
- Button padding increases with screen size for comfortable TV-distance interaction
- Page container (`#root`) switches to CSS Grid at large-screen breakpoints and above
- Responsive layout for index.html and demo page goes in `ai-card.css` media queries — no `<style>` block in HTML

### New Template Responsive Checklist

- [ ] `ai-card.css` includes 4 media query breakpoints (480 / 768 / 1024 / 1440)
- [ ] All sized properties (width, height, font-size, padding, gap, border-radius) are covered at each breakpoint
- [ ] `index.html` `#root` switches to grid layout at 768px+
- [ ] Demo page `.grid` containers adapt to the corresponding breakpoints

---

## Notes

1. **Group by visual layout:** Don't be misled by the card_type field name. Five card_types share the text-card template because their DOM structure is identical.
2. **Two architecture families:** The project has two families — Web Components (text/homework/media/english-word/comic) and Standalone (answer-card). Web Components use `<ai-card>` + Shadow DOM + shared engine. The Standalone card is a traditional HTML/CSS/JS app with no Shadow DOM.
3. **No extra JSON fields (Web Component cards):** Strictly follow the documented schema. Do not add custom fields like `subject`, `teacher`, `submit_count`.
4. **Answer card doesn't use ai-card.js/css:** It has its own `app.js` and `style.css`. Modifying it follows traditional web app patterns, not the Web Component JSON-driven pattern.
5. **Quote handling:** Use 「」for Chinese quotes inside JSON strings to avoid parser conflicts with ASCII double quotes.
6. **Naming convention:** JSON file names in kebab-case, named by purpose (e.g. `oral-practice.json`).
7. **JS is lean:** Each Web Component folder's `ai-card.js` only contains the PALETTE colors and render functions needed by that template. No dead code.
8. **CSS is lean:** Each folder's CSS only contains the style classes used by that template.
9. **Custom element guard:** Use `customElements.get('ai-card')` check before `define` to support loading multiple JS files on the demo page.
10. **Sync updates:** After adding cards or templates, always update the demo page and this skill file.
11. **metadata.md required:** Every template folder must have a complete metadata.md (TOC, schema, field table, DOM tree, adaptive rules, variant table, theme table, responsive table, rendering notes).
12. **5-device responsive:** All CSS and page layouts must cover phone, tablet, large screen, desktop, and TV breakpoints.

---
name: comic
description: Generate paginated comic-strip cards. Video player + one frame per page with prev/next navigation, each in comic-card/ folder with CSS + JS + JSON + metadata.
---

# /comic — Comic Strip Card Generator

Accepts natural language descriptions or JSON data for comic-strip style cards. Each card has a `<video>` player at top and one comic frame at a time with prev/next page navigation, like flipping through a manga.

---

## Core Decision: Reuse vs. New Template

```
User description / JSON
    │
    ▼
┌─────────────────────────────────────────┐
│ 1. Extract visual features               │
│    - Video player + comic strip grid?    │
│    - Different panel layout needed?      │
│    - Different interaction pattern?      │
└─────────────────────────────────────────┘
    │
    ├─ Matches comic-strip template ──→ [REUSE] Add JSON to comic-card/
    │
    └─ No match ──→ [NEW] Create folder + CSS + JS + HTML + MD
```

**Key principle: group by visual layout.** If it has a video on top and comic frames below, reuse `comic-card/`. Only create a new template when the layout is fundamentally different (e.g., single-panel cartoon, manga page with sound effects, horizontal scroll strip).

---

## 1 Existing Template

### comic-card — Comic Strip Cards

**Visual signature:** `<video>` player at top (with controls) + single comic frame (image + speech bubbles) + prev/next page navigation with page indicator.

**DOM skeleton:**
```
comic-card
  ├── video-area
  │     └── <video controls src="...">
  └── card-body
        ├── hdr (title + subtitle)
        ├── desc (description)
        ├── comic-viewport (single frame)
        │     ├── page-indicator ("1 / 6")
        │     ├── frame-img (single image, rounded)
        │     └── bubbles
        │           ├── bubble.left (blue, first text)
        │           ├── bubble.right (pink, second text)
        │           └── bubble.center (green, third+ text)
        └── nav
              ├── nav-btn[data-nav="prev"] ← 上一页
              └── nav-btn.primary[data-nav="next"] 下一页 →
```
```

**Matching rules (any one match is sufficient):**
- Has a video at the top and multiple image+text panels
- Comic/manga style sequential storytelling, one panel per page
- Each panel has an image + speech bubble dialogue
- Prev/next page navigation through 4-6 frames

**Existing variants:** TBD (1 JSON file to start)

**Supported card_type values:** `comic_strip`

**Supported icon values:** `comic` (to add a new one, append to the ICONS object)

**Supported theme values:** `comic` — mapped to warm amber/orange via THEME_MAP (to add a new theme, append to THEME_MAP and PALETTE)

**Frame structure:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image` | string | Yes | Frame character/scene image URL |
| `texts` | string[] | Yes | Dialogue texts, rendered as alternating speech bubbles |

**Bubble rules:**
- texts[0] → `.bubble.left` (blue, left-aligned)
- texts[1] → `.bubble.right` (pink, right-aligned)
- texts[2+] → `.bubble.center` (green, centered, bold)

---

## JSON Schema

```json
{
  "schema_version": "1.0",
  "card_type": "comic_strip",
  "title": "We Are Twins!",
  "subtitle": "Unit 1 · Describing People",
  "description": "Watch the video, then read the comic dialogue below.",
  "button_text": "查看完整内容",
  "video_url": "https://example.com/video.mp4",
  "theme": "comic",
  "frames": [
    {
      "image": "https://example.com/panel1.png",
      "texts": ["Hi, I'm Meimei.", "I'm Feifei.", "We are twins."]
    },
    {
      "image": "https://example.com/panel2.png",
      "texts": ["I have big eyes.", "Me too."]
    }
  ],
  "layout": {
    "variant": "comic_strip",
    "icon": "comic"
  }
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `schema_version` | Yes | Fixed `"1.0"` |
| `card_type` | Yes | Fixed `"comic_strip"` |
| `title` | Yes | Card title, displayed above video |
| `subtitle` | No | Subtitle below title (e.g. unit/chapter info) |
| `description` | No | Brief description above the comic grid |
| `button_text` | No | Button label, defaults to "查看完整内容" |
| `video_url` | Yes | Video source URL for `<video>` tag |
| `theme` | No | Semantic theme name, defaults to `"comic"` |
| `frames` | Yes | Array of 4-6 frame objects |
| `frames[].image` | Yes | Frame image URL |
| `frames[].texts` | Yes | Array of dialogue strings (rendered as alternating bubbles) |
| `layout.variant` | No | Fixed `"comic_strip"` |
| `layout.icon` | No | Icon key, defaults to `"comic"` |

---

## Reuse Flow (Add Comic Data)

### Step 1: Create the JSON File

Add a new JSON file in `comic-card/`. File name in kebab-case, named by topic (e.g. `ordering-food.json`, `at-the-doctor.json`).

Follow the schema above. Keep `frames` to 4-6 entries — fewer than 4 looks sparse, more than 6 overcrowds the grid.

### Step 2: Update JS auto-fetch list

In `comic-card/ai-card.js`, append the new filename to the `FILES` array:

```javascript
var FILES = ['ordering-food.json', 'at-the-doctor.json'];
```

### Step 3: Update ai-card-demo.html

In the root `ai-card-demo.html`, append to the `CARDS` array:

```javascript
{folder:'comic-card', group:'连环画', file:'ordering-food.json', data:{/* complete JSON */}},
```

### Step 4: Validate

Open `comic-card/index.html` and `ai-card-demo.html` in a browser. Confirm:
- Video player renders with controls
- Comic frames display in correct grid layout
- Responsive breakpoints work (2→3→4 columns)
- Dialogue text is readable at all sizes

---

## New Template Flow (Different Comic Layout)

When the comic layout is fundamentally different from the existing one (e.g., horizontal scroll manga, full-page comic with sound effects, single-panel cartoon), create a new template folder.

### Steps to Create a New Comic Template

**1. Create folder**, named `{feature}-card` (kebab-case).

**2. Create `ai-card.css`** — include responsive breakpoints (480/768/1024/1440).

**3. Create `ai-card.js`** — Web Component skeleton with:
- `PALETTE` + `THEME_MAP` for color theming
- `cardHTML(d)` function returning template HTML
- `customElements.define('ai-card', ...)` with `_connected` guard
- `window.renderCards(containerId, cards)` for demo page
- Auto-fetch IIFE for standalone `index.html`

**4. Create `index.html`** — minimal HTML (zero logic):
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Comic Card</title>
<link rel="stylesheet" href="ai-card.css">
</head>
<body>
<div id="root"></div>
<script src="ai-card.js"></script>
</body></html>
```

**5. Create at least one JSON data file.**

**6. Create `metadata.md`** — include: file structure, JSON schema, field table, DOM tree, adaptive rules, responsive breakpoints.

**7. Update `ai-card-demo.html`** — add template function, `getTemplate()` routing, THEME_MAP/ICONS entries, and CARDS entries.

**8. Update this skill file** — add the new template as a 2nd entry under "Existing Templates."

---

## Theme → Color Mapping

| theme | Color | Used By | Typical Use |
|-------|-------|---------|-------------|
| `comic` | #f59e0b (amber) | comic | Comic strip / dialogue |

> To add a new theme, append to `THEME_MAP` and `PALETTE` in `ai-card.js`.

---

## Responsive Design (5 Device Targets)

| Device | Breakpoint | Card max-width | Comic Grid | Frame size |
|--------|-----------|---------------|------------|------------|
| Phone | < 480px | 380px | 2 columns | ~160px wide |
| Tablet | ≥ 480px | 420px | 2 columns | ~185px wide |
| Large screen | ≥ 768px | 460px | 3 columns | ~140px wide |
| Desktop | ≥ 1024px | 500px | 3 columns | ~155px wide |
| TV | ≥ 1440px | 560px | 4 columns | ~130px wide |

### Responsive Checklist for New Comic Templates
- [ ] `ai-card.css` includes 4 media query breakpoints (480/768/1024/1440)
- [ ] Comic grid columns adjust at each breakpoint
- [ ] Frame images, speaker labels, and dialogue text scale proportionally
- [ ] Video player height adjusts to maintain ~16:9 ratio
- [ ] `index.html` uses zero-logic HTML (no `<style>` or inline `<script>`)

---

## Notes

1. **frames array is core data**: Unlike text cards where all data fits in standard fields, comic cards need `frames` — this is the essential content, not "extra" data.
2. **4-6 frames ideal**: Fewer than 4 makes the grid look empty; more than 6 makes individual frames too small on mobile.
3. **Each text is short**: Each dialogue string should be 1-2 sentences max. Longer text won't fit in the speech bubble style.
4. **Bubble alternation**: texts[0] = left (blue), texts[1] = right (pink), texts[2+] = center (green). Use 2-3 texts per frame for best visual rhythm.
5. **video_url with controls**: Always render `<video controls>` so users can play/pause. No autoplay.
6. **No extra JSON fields**: Only use the documented fields. For comic cards, `video_url` and `frames` are documented fields.
7. **Naming convention**: JSON file names in kebab-case, named by topic (e.g. `ordering-food.json`).
8. **Sync updates**: After adding cards or templates, always update the demo page, this skill file, and the card skill file.
9. **metadata.md required**: Every template folder must have a complete metadata.md.
10. **5-device responsive**: All CSS must cover phone, tablet, large screen, desktop, and TV breakpoints.

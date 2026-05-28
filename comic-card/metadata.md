# comic-card — Comic Strip Card (Paginated)

## File Structure
```
comic-card/
  ai-card.css      — Video player + single-frame viewport + nav buttons + 5-device responsive
  ai-card.js       — Web Component + pagination logic (prev/next, page indicator)
  index.html       — Zero-logic entry page
  data.json        — "We Are Twins!" twin dialogue comic strip (6 panels)
  metadata.md      — This file
```

## JSON Schema

| Field | Required | Description |
|-------|----------|-------------|
| `schema_version` | Yes | Fixed `"1.0"` |
| `card_type` | Yes | Fixed `"comic_strip"` |
| `title` | Yes | Card title |
| `subtitle` | No | Subtitle below title |
| `description` | No | Brief description above the comic |
| `button_text` | No | Not rendered (nav buttons replace it) |
| `video_url` | Yes | Video source for `<video controls>` |
| `theme` | No | Defaults to `"comic"` |
| `frames` | Yes | Array of 4-6 frame objects |
| `frames[].image` | Yes | Frame image URL |
| `frames[].texts` | Yes | Array of dialogue strings |
| `layout.variant` | No | Fixed `"comic_strip"` |
| `layout.icon` | No | Icon key, defaults to `"comic"` |

## DOM Tree
```
ai-card (Shadow DOM)
  └── .comic-card
        ├── .video-area
        │     └── <video controls src="...">
        └── .card-body
              ├── .hdr (title + subtitle)
              ├── .desc (description, optional)
              ├── .comic-viewport
              │     ├── .page-indicator ("1 / 6")
              │     ├── .frame-img (single image)
              │     └── .bubbles
              │           ├── .bubble.left
              │           ├── .bubble.right
              │           └── .bubble.center
              └── .nav
                    ├── .nav-btn[data-nav="prev"] (disabled on first page)
                    └── .nav-btn.primary[data-nav="next"] (disabled on last page)
```

## Speech Bubble Rules
- texts[0] → `.bubble.left` (blue, left-aligned)
- texts[1] → `.bubble.right` (pink, right-aligned)
- texts[2+] → `.bubble.center` (green, centered, bold)

## Pagination
- Single frame displayed at a time
- Prev/Next buttons navigate between frames
- Page indicator shows "current / total"
- Prev disabled on first frame, Next disabled on last frame

## Responsive Breakpoints

| Device | Width | Card max-width |
|--------|-------|---------------|
| Phone | < 480px | 380px |
| Tablet | ≥ 480px | 440px |
| Large | ≥ 768px | 520px |
| Desktop | ≥ 1024px | 600px |
| TV | ≥ 1440px | 720px |

## Theme
- `comic` → amber (#f59e0b) for primary nav button

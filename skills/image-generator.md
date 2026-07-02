---
name: image-generator
description: 图片生成。根据 prompt 生成教学插图，替换卡片 data.json 中的 target_url。
---

# image-generator — 替换 target_url

读取卡片数据中的主体信息，生成绘画提示词，调用图片生成 API，用返回的图片 URL 替换 `data.json` 中的 `target_url`。

## 替换流程

```
data.json  →  提取主体（title / subtitle / description）
    │
    ▼
调用 LLM 生成英文绘画提示词
    │
    ▼
调用 DashScope wan2.7 API 生成图片  →  下载  →  rembg 去底  →  上传 OSS 拿到 URL
    │
    ▼
data.json 的 target_url 替换为返回的图片地址
```

**每一步必须严格按顺序执行：**

### 1. 提取主体，生成绘画提示词

从卡片的 `data.json` 中取 `subtitle`（英文主体词）和 `description`（中文翻译），调用 LLM 生成英文绘画提示词。

```
输入: apple / 苹果
输出: "A cute cartoon apple with a red surface, green leaf on top, simple rounded shape, solid white background, clean educational illustration style, no shadows"
```

提示词必须包含 `white background` 和 `no shadows`，确保产出适合去底。

### 2. 调用 DashScope wan2.7 生成图片

用第 1 步的提示词直接调 DashScope API 生成图片，拿到图片文件后 `rembg` 去底。

### 3. 上传 OSS 拿到 URL

去底后的 PNG 上传到 OSS，拿到可访问的 URL。

### 4. 替换 data.json 的 target_url

用 OSS 返回的 URL 替换 `data.json` 中的 `target_url`：

```
替换前: "target_url": "https://works.blazegraph.site/.../img16.png"
替换后: "target_url": "<第3步 OSS 返回的 URL>"
```

---

## 注意事项

1. **提示词决定产出质量:** LLM 生成的提示词必须具体、包含 `white background`，否则去底后边缘残留杂色
2. **API Key:** DashScope API Key 通过环境变量 `DASHSCOPE_API_KEY` 传入
3. **超时:** DashScope wan2.7 图片生成通常 8-15s，复杂提示词可能到 30s
4. **rembg 首次运行会下载模型:** `u2net` 约 176MB，首次调用自动下载到 `~/.u2net/`，后续直接使用缓存
5. **输出固定为 PNG:** 去底依赖透明通道，只有 PNG 支持

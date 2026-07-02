---
name: resource_lookup
description: Look up existing card resources — homework, textbooks, activities, media, word cards, comics, English sentences. Searches across all 8 template folders, outputs structured candidates. Does NOT render cards.
---

# resource_lookup — 资源查找

查已有资源：作业、课本、活动、媒体、单词卡、连环画、问答等。
输出结构化候选 JSON。**不渲染卡片**，不生成 HTML。

---

## 职责边界

| 职责 | resource_lookup（本技能） | card_render（渲染技能） |
|------|--------------------------|------------------------|
| 搜索已有资源 | ✅ | ❌ |
| 按分类/学科/主题过滤 | ✅ | ❌ |
| 输出结构化候选 | ✅ | ❌ |
| 接收 templateId + data 渲染卡片 | ❌ | ✅ |
| 生成 ai_card / webview | ❌ | ✅ |
| 决定使用哪个模板 | ✅（建议 templateId） | ❌ |

**调用链:** `resource_lookup` → 用户确认候选 → `card_render` 渲染

---

## 资源目录

### 1. 作业提醒 — homework-card/

**templateId:** `homework-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `homework_reminder`

| 文件 | theme | 学科 | 颜色 | 标题示例 |
|------|-------|------|------|---------|
| `chinese.json` | chinese | 语文 | #dc2626 红 | 语文 · 阅读理解训练 |
| `math.json` | math | 数学 | #3b82f6 蓝 | 数学 · 第三章分数练习 |
| `english.json` | english | 英语 | #16a34a 绿 | 英语 · Unit 4 Daily Routines |

**搜索关键词:** 作业、语文、数学、英语、学科、练习、提醒、老师、班级

---

### 2. 文本卡片 — text-card/

**templateId:** `text-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `h5_entry` | `assistant_welcome` | `recommendation` | `task` | `health_advice`

| 文件 | card_type | theme | 图标 | 场景 |
|------|-----------|-------|------|------|
| `h5-ai-assistant.json` | h5_entry | general | ai | 炎图 AI 助手入口 |
| `h5-essay.json` | h5_entry | general | link | 作文范文链接 |
| `edu-ai.json` | assistant_welcome | ai | sparkle | 教育 AI 助手欢迎 |
| `medical-ai.json` | assistant_welcome | health | health | 医疗 AI 助手欢迎 |
| `oral-practice.json` | recommendation | recommendation | audio | 英语口语练习推荐 |
| `weekly-report.json` | task | task | task | 教学周报协作 |
| `medication-reminder.json` | health_advice | health | health | 服药提醒 |

**搜索关键词:** 入口、助手、推荐、任务、健康、AI、欢迎、协作、练习、提醒、报告

---

### 3. 媒体预览 — media-card/

**templateId:** `media-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `media_preview`

| 文件 | theme | 图标 | 类型 | 时长 | 标题示例 |
|------|-------|------|------|------|---------|
| `class-video.json` | video | video | 视频 | 42:18 | 课堂录像 · 分数的加减法 |

**搜索关键词:** 视频、音频、图片、文件、媒体、播放、预览、录像、课堂

---

### 4. 英语单词 — english-word-card/

**templateId:** `english-word-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `english_word`

| 文件 | theme | 字母 | 单词 | 中文 | 标题 |
|------|-------|------|------|------|------|
| `data.json` | abc | Aa | apple | 苹果 | ABC · 字母启蒙 |

**搜索关键词:** 英语、单词、字母、启蒙、发音、学习、ABC、phonics

---

### 5. 连环画 — comic-card/

**templateId:** `comic-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `comic_strip`

| 文件 | theme | 单元数 | 面板数 | 内容 |
|------|-------|--------|--------|------|
| `data.json` | comic | 6 (Units 1-6) | 28 | PEP外研版 · Pets/Animals/Body/Family/Toys/Food |

**搜索关键词:** 连环画、漫画、英语、PEP、外研版、对话、故事、分页、视频

---

### 6. AI 问答 — answer-card/

**templateId:** `answer-card`
**架构:** Standalone (iframe / 直接打开)
**card_type:** `qa_answer`

| 入口 | 类型 | 说明 |
|------|------|------|
| `answer-card/index.html` | 独立页面 | AI 知识问答，输入问题 → API 返回答案 + 文件来源 |

**搜索关键词:** 问答、AI、知识库、搜索、提问、答案

---

### 7. 英语句子展示 — english-sentence-card/

**templateId:** `english-sentence-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `english_sentence`

| 文件 | theme | 徽章 | 句子 | 翻译 |
|------|-------|------|------|------|
| `data.json` | sentence | 每日一句 | The best preparation for tomorrow is doing your best today. | 为明天做的最好准备，就是今天做到最好。 |

**搜索关键词:** 英语、句子、每日一句、发音、跟读、口语、朗读、每日英语

---

### 8. 英语句子输入 — english-input-card/

**templateId:** `english-input-card`
**架构:** Web Component (`<ai-card>`)
**card_type:** `english_sentence`

| 入口 | 类型 | 说明 |
|------|------|------|
| `english-input-card/index.html` | 独立页面 | 可编辑输入框 + DeepSeek API 实时翻译 + TTS 发音 + 跟读打分 |

**搜索关键词:** 英语、输入、翻译、句子、自由输入、实时翻译、口语练习

---

## 查找流程

```
用户自然语言查询
    │
    ▼
┌──────────────────────────────────────┐
│ 1. 提取关键信号                        │
│    - 学科相关? → homework-card         │
│    - 媒体/播放? → media-card           │
│    - 英语单词/字母? → english-word-card │
│    - 漫画/对话/故事? → comic-card       │
│    - AI/问答/知识? → answer-card        │
│    - 通用入口/推荐/任务? → text-card    │
│    - 无明确信号? → 全文关键词匹配        │
└──────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────┐
│ 2. 在匹配的文件夹中查找 JSON 数据文件    │
│    - 按 theme / card_type / 标题 匹配   │
│    - 多个匹配时按相关度排序              │
└──────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────┐
│ 3. 输出结构化候选列表                   │
│    - 包含 templateId + 资源文件 + 摘要   │
│    - 附推荐理由                         │
└──────────────────────────────────────┘
```

---

## 输出格式

查找结果按以下结构输出：

```json
{
  "query": "用户原始查询",
  "candidates": [
    {
      "templateId": "homework-card",
      "folder": "homework-card/",
      "file": "math.json",
      "card_type": "homework_reminder",
      "theme": "math",
      "title": "数学 · 第三章分数练习",
      "subtitle": "王老师 · 三年级二班",
      "description": "完成课本第42-44页练习题 1-15…",
      "match_reason": "匹配学科关键词「数学」",
      "relevance": "high"
    }
  ],
  "suggestion": "推荐使用 templateId='homework-card' + file='math.json'"
}
```

**字段说明：**

| 字段 | 说明 |
|------|------|
| `templateId` | 模板文件夹名，传给 `card_render` 渲染 |
| `folder` | 模板文件夹路径 |
| `file` | JSON 数据文件名 |
| `card_type` | 卡片类型标识 |
| `theme` | 语义主题名 |
| `match_reason` | 匹配依据（一句话） |
| `relevance` | `high` / `medium` / `low` |
| `suggestion` | 推荐下一步操作 |

---

## 关键词 → 模板映射速查

| 用户说… | 查… | templateId |
|---------|------|------------|
| 作业、练习、语文、数学、英语学科、老师 | 学科 → homework-card/ | `homework-card` |
| 视频、音频、播放、录像、媒体 | 媒体类型 → media-card/ | `media-card` |
| 单词、字母、英语启蒙、发音、ABC | 启蒙 → english-word-card/ | `english-word-card` |
| 连环画、漫画、对话、故事、分页 | 漫画 → comic-card/ | `comic-card` |
| AI问答、知识库、提问、搜索答案 | 问答 → answer-card/ | `answer-card` |
| 英语句子、每日一句、发音、跟读、口语 | 句子展示 → english-sentence-card/ | `english-sentence-card` |
| 英语输入、翻译、自由输入、实时翻译 | 句子输入 → english-input-card/ | `english-input-card` |
| 入口、助手、推荐、报告、提醒、欢迎 | 场景 → text-card/ | `text-card` |

---

## 注意事项

1. **只查不渲染:** 本技能输出候选 JSON，不生成 `<ai-card>` 或 iframe。渲染交给 `card_render`。
2. **资源 = 已有 JSON 数据文件:** 每个 JSON 文件是一个资源变体，包含完整的卡片数据。
3. **多个匹配时全部列出:** 按相关度排序，让用户选择，不要自作主张只返回一个。
4. **无匹配时明确告知:** 如果找不到已有资源，如实说明，建议新建数据文件（参见 `card` 技能）。
5. **templateId 必须准确:** 8 个有效值 — `text-card`, `homework-card`, `media-card`, `english-word-card`, `comic-card`, `answer-card`, `english-sentence-card`, `english-input-card`。
6. **答案卡特殊:** answer-card 是 Standalone 架构，没有 JSON 数据文件变体，只有一个入口页面。查找时返回入口信息即可。

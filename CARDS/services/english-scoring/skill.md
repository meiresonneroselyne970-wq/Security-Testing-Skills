---
name: english-scoring
description: Call DeepSeek API to score English pronunciation for word/sentence/input cards. Supports 3 card types with tailored scoring dimensions and prompts. Use when the user asks for pronunciation evaluation, speaking scoring, or AI-powered English oral scoring.
---

# english-scoring — 英语口语 AI 评分

Python 服务模块，调用 DeepSeek API 对 english-word-card、english-sentence-card、english-input-card 三类卡片的跟读进行多维度 AI 评分。通过 FastAPI 暴露 HTTP 接口，卡片前端直接 `fetch` 调用。

---

## 职责边界

| 职责 | english-scoring（本技能） | card_render（渲染技能） |
|------|--------------------------|------------------------|
| 接收卡类型 + 参考文本 + 识别文本调用评分 | ✅ | ❌ |
| 返回多维度评分 + 评语 + 建议 | ✅ | ❌ |
| 降级到本地相似度评分（前端侧） | ❌ | ❌ |
| 渲染 ai_card HTML | ❌ | ✅ |
| 查已有资源/数据文件 | ❌ | ✅ |

**调用链:** 卡片前端跟读 → 语音识别 → `fetch('localhost:8800/api/score')` → server.py → scoring_service.py → DeepSeek API → 返回评分结果展示

---

## 评分维度速查

| 卡片类型 | 维度 | 权重 | 说明 |
|---------|------|------|------|
| **english_word** | 发音准确度 | 45% | 音素发音是否标准，元音和辅音是否清晰，重音位置 |
| | 完整性 | 30% | 是否完整读出单词，有无漏读音节或多余音节 |
| | 流利度 | 25% | 发音是否流畅自然，有无不必要的停顿或重复 |
| **english_sentence** | 发音准确度 | 30% | 每个单词的发音是否标准，重点词汇清晰度 |
| | 完整性 | 25% | 是否完整读出所有单词，有无遗漏或替换 |
| | 流利度 | 25% | 朗读是否流畅，词间衔接（连读、失去爆破）是否自然 |
| | 语调自然度 | 20% | 语调是否符合英语模式，重读弱读是否恰当 |
| **english_input** | 发音准确度 | 28% | 单词发音标准度，特殊发音（连读、弱读）处理 |
| | 完整性 | 20% | 是否完整读出输入的所有内容 |
| | 流利度 | 22% | 朗读流畅度，语速适中，无不自然停顿 |
| | 语调自然度 | 18% | 升降调是否自然，句子节奏感 |
| | 语法与表达 | 12% | 输入原句的语法和表达是否地道（辅助评估） |

---

## 文件结构

```
services/english-scoring/
├── server.py            ← FastAPI HTTP 服务 (POST /api/score + GET /api/health)
├── scoring_service.py   ← 核心评分逻辑（async score() + 降级 + CLI）
├── prompts.py           ← 三套完整系统提示词 + 用户提示词模板
├── config.py            ← DeepSeek API 配置 + 评分维度权重
├── requirements.txt     ← httpx fastapi uvicorn pydantic
└── README.md            ← 使用文档
```

---

## 启动服务

```bash
cd CARDS/services/english-scoring/
pip install -r requirements.txt
python server.py
# → Uvicorn running on http://0.0.0.0:8800
```

## API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/score` | AI 评分 |
| `GET` | `/api/health` | 健康检查 |

### 请求

```json
{
  "card_type": "english_word",
  "target_text": "apple",
  "recognized_text": "appel"
}
```

### 返回

```json
{
  "overall": 85,
  "dimensions": [
    { "key": "pronunciation", "label": "发音准确度", "score": 88, "weight": 0.45, "comment": "..." },
    { "key": "completeness",   "label": "完整性",     "score": 95, "weight": 0.30, "comment": "..." },
    { "key": "fluency",        "label": "流利度",     "score": 78, "weight": 0.25, "comment": "..." }
  ],
  "feedback": "读得很棒！发音整体清晰……",
  "highlights": "元音发音准确，重音位置正确",
  "suggestions": "可以尝试把嘴巴张得更大一些来发/æ/音",
  "is_fallback": false
}
```

---

## 集成到卡片前端

### 架构

```
english-word-card/ai-card.js  ──┐
english-sentence-card/ai-card.js ──┤ fetch('localhost:8800/api/score')
english-input-card/ai-card.js  ──┘       │
                                          ▼
                                  server.py (FastAPI :8800)
                                          │
                                          ▼
                                  scoring_service.py
                                          │
                                          ▼
                                  DeepSeek API
```

卡片 JS 已内置集成 — `listenAndCheck()` 中跟读完成后直接 `fetch` 评分 API。无需引入额外 JS 文件。

### 跟读评分流程

```
用户点击"跟读"
  → TTS 范读
  → 等 1s（避免扬声器回声被麦克风收录）
  → SpeechRecognition 收音
  → fetch('http://localhost:8800/api/score', { card_type, target_text, recognized_text })
  → 成功 → 展示 AI 评分卡片（综合分 + 各维度进度条 + 评语 + 建议）
  → 失败 → 降级到本地相似度判断（原有逻辑）
```

### 降级策略

前端 `showAIRating` 检查 `result.is_fallback`：
- `true` → 走 `showLocalResult()`（原有本地正确/错误判断）
- `false` → 渲染 AI 评分卡片

---

## 配置

```python
# config.py
DEEPSEEK_CONFIG = {
    "api_url": "https://api.deepseek.com/v1/chat/completions",
    "api_key": "sk-xxx",
    "model": "deepseek-v4-pro",
    "temperature": 0.3,
    "max_tokens": 4096,
    "timeout": 60,
}
```

---

## 提示词设计

三套独立系统提示词（`prompts.py`），每套包含：

1. **角色定义** — 根据卡片类型设定教练角色（启蒙教练/朗读教练/口语教练）
2. **评分维度 + 权重** — 逐维度说明评分依据，标注中文母语者常见偏误（th/s、v/w、词尾辅音脱落等）
3. **评分标准** — 5 级档位（90-100 优秀 → 60以下 需加强）
4. **JSON 输出格式** — 含完整示例，配合 `response_format: { type: "json_object" }`
5. **注意事项** — 中文评语、鼓励为主、面向儿童/初学者、只输出 JSON

---

## 注意事项

1. **先启动 server.py:** 评分服务需要单独运行在 `localhost:8800`，卡片不会自动启动它
2. **API Key:** 生产环境用环境变量，不要硬编码在 `config.py`
3. **超时:** 默认 60s，单词评分 2-3s 返回，句子评分 3-6s
4. **max_tokens: 4096:** 评分 JSON 含多维度中文评语，不能太小否则截断
5. **语音识别误差:** 提示词已说明"可能存在误差"，引导 AI 基于文本相似度合理推断
6. **仅基于文本评分:** 输入是语音识别文本（非音频），通过对比参考文本和识别文本的差异推断发音问题

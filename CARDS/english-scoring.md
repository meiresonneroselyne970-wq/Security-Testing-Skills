# 英语评分服务 — [services/english-scoring/](./services/english-scoring/)

Python 服务模块，调用 DeepSeek API 对三类英语卡片（english-word、english-sentence、english-input）的跟读进行多维度 AI 评分。

| 属性 | 值 |
|------|-----|
| **框架** | FastAPI + Uvicorn |
| **端口** | 8800 |
| **API** | DeepSeek（deepseek-v4-pro） |
| **对应技能** | [services/english-scoring/skill.md](./services/english-scoring/skill.md) |
| **适用卡片** | [04-english-word-card](04-english-word-card.md)、[07-english-sentence-card](07-english-sentence-card.md)、[08-english-input-card](08-english-input-card.md) |

---

## 评分维度

### english_word

| 维度 | 权重 |
|------|------|
| 发音准确度 | 45% |
| 完整性 | 30% |
| 流利度 | 25% |

### english_sentence / english_input

| 维度 | 权重 |
|------|------|
| 发音准确度 | 30% / 28% |
| 完整性 | 25% / 20% |
| 流利度 | 25% / 22% |
| 语调自然度 | 20% / 18% |
| 语法与表达 | — / 12% |

---

## 启动服务

```bash
cd services/english-scoring/
pip install -r requirements.txt
python server.py
# → Uvicorn running on http://0.0.0.0:8800
```

## API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/score` | AI 评分 |
| `GET` | `/api/health` | 健康检查 |

## 架构

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

## 跟读评分流程

```
用户点击"跟读"
  → TTS 范读
  → 等 1s（避免扬声器回声）
  → SpeechRecognition 收音
  → fetch('http://localhost:8800/api/score', { card_type, target_text, recognized_text })
  → 成功 → 展示 AI 评分卡片（综合分 + 各维度进度条 + 评语 + 建议）
  → 失败 → 降级到本地相似度判断
```

## 文件结构

```
services/english-scoring/
├── server.py            ← FastAPI HTTP 服务
├── scoring_service.py   ← 核心评分逻辑
├── prompts.py           ← 三套系统提示词
├── config.py            ← DeepSeek API 配置
├── requirements.txt     ← httpx fastapi uvicorn pydantic
├── README.md            ← 使用文档
└── skill.md             ← 英语评分技能定义
```

---

> 详细 API 文档、提示词设计、配置说明见 [services/english-scoring/skill.md](./services/english-scoring/skill.md)

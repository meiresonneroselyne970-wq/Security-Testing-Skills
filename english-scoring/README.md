# english-scoring — 英语口语 AI 评分服务

调用 DeepSeek API 对三种英语学习卡片（单词、句子展示、句子输入）的跟读进行多维度 AI 评分。

## 目录

- [快速开始](#快速开始)
- [评分维度](#评分维度)
- [API 参考](#api-参考)
- [CLI 用法](#cli-用法)
- [HTTP 服务集成](#http-服务集成)
- [配置](#配置)
- [提示词设计](#提示词设计)

---

## 快速开始

```bash
# 安装依赖
pip install httpx

# CLI 调用
cd english-scoring/
python scoring_service.py english_word apple appel
```

```python
# Python 调用
import asyncio
from scoring_service import score

result = asyncio.run(score(
    card_type="english_sentence",
    target_text="The best preparation for tomorrow is doing your best today.",
    recognized_text="the best preparation for tomorrow is doing your best today"
))

print(result["overall"])    # 85
print(result["feedback"])   # "读得很好！发音比较标准……"
for d in result["dimensions"]:
    print(f"{d['label']}: {d['score']}/100 — {d['comment']}")
```

---

## 评分维度

### english_word（单词卡片）

| 维度 | 权重 | 说明 |
|------|------|------|
| 发音准确度 | 45% | 音素发音、元音辅音清晰度、重音位置 |
| 完整性 | 30% | 是否完整读出，有无漏读/多余音节 |
| 流利度 | 25% | 是否流畅，有无停顿或重复 |

### english_sentence（句子卡片）

| 维度 | 权重 | 说明 |
|------|------|------|
| 发音准确度 | 30% | 各单词发音标准度 |
| 完整性 | 25% | 所有单词是否完整读出 |
| 流利度 | 25% | 词间衔接、连读、失去爆破 |
| 语调自然度 | 20% | 语调模式、重读弱读 |

### english_input（输入句子卡片）

| 维度 | 权重 | 说明 |
|------|------|------|
| 发音准确度 | 28% | 单词发音、连读弱读处理 |
| 完整性 | 20% | 是否完整读出输入内容 |
| 流利度 | 22% | 语速、流畅度 |
| 语调自然度 | 18% | 升降调、句子节奏 |
| 语法与表达 | 12% | 原句语法正确性和表达地道性 |

---

## API 参考

### `score(card_type, target_text, recognized_text, **kwargs)`

异步评分函数，返回评分结果字典。

**参数:**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `card_type` | str | ✅ | `english_word` / `english_sentence` / `english_input` |
| `target_text` | str | ✅ | 参考文本（目标单词/句子） |
| `recognized_text` | str | ✅ | 语音识别文本（用户实际发音） |
| `api_key` | str | ❌ | 覆盖默认 API Key |
| `api_url` | str | ❌ | 覆盖默认 API URL |
| `model` | str | ❌ | 覆盖默认模型 |
| `timeout` | int | ❌ | 覆盖默认超时时间（秒） |

**返回:**

```python
{
    "overall": int,          # 综合得分 0-100
    "dimensions": [          # 各维度评分
        {
            "key": str,      # 维度标识
            "label": str,    # 维度中文名
            "score": int,    # 得分 0-100
            "weight": float, # 权重
            "comment": str   # 维度评语
        },
        ...
    ],
    "feedback": str,         # 总体中文评语
    "highlights": str,       # 亮点分析
    "suggestions": str,      # 改进建议
    "is_fallback": bool      # 是否为降级结果
}
```

### `score_sync(card_type, target_text, recognized_text, **kwargs)`

同步版本，内部使用 `asyncio.run()`。

### `quick_score(target_text, recognized_text)`

本地词重叠相似度计算（0-100），不调用 API。用于降级或即时反馈。

---

## CLI 用法

```bash
# 单词评分
python scoring_service.py english_word apple appel

# 句子评分
python scoring_service.py english_sentence "Hello world" "Hello word"

# 输入句子评分
python scoring_service.py english_input "I love learning English" "I love learn English"
```

输出为格式化的 JSON。

---

## HTTP 服务集成

### FastAPI 示例

```python
from fastapi import FastAPI
from pydantic import BaseModel
from scoring_service import score

app = FastAPI()

class ScoreRequest(BaseModel):
    card_type: str
    target_text: str
    recognized_text: str

@app.post("/api/score")
async def score_endpoint(req: ScoreRequest):
    result = await score(req.card_type, req.target_text, req.recognized_text)
    return result
```

### Flask 示例

```python
from flask import Flask, request, jsonify
from scoring_service import score_sync

app = Flask(__name__)

@app.route("/api/score", methods=["POST"])
def score_endpoint():
    data = request.get_json()
    result = score_sync(
        data["card_type"],
        data["target_text"],
        data["recognized_text"]
    )
    return jsonify(result)
```

---

## 配置

所有配置集中在 `config.py`：

```python
DEEPSEEK_CONFIG = {
    "api_url": "https://api.deepseek.com/v1/chat/completions",
    "api_key": "sk-xxx",          # 生产环境改用环境变量
    "model": "deepseek-v4-pro",
    "temperature": 0.3,
    "max_tokens": 1024,
    "timeout": 15,
}
```

### 环境变量覆盖（推荐）

```bash
export DEEPSEEK_API_KEY="sk-xxx"
```

在代码中读取：

```python
import os
api_key = os.environ.get("DEEPSEEK_API_KEY", DEEPSEEK_CONFIG["api_key"])
```

---

## 提示词设计

三套独立系统提示词（`prompts.py`），每套均经过设计：

1. **角色定义** — 根据卡片类型设定教练角色（启蒙教练/朗读教练/口语教练）
2. **评分维度 + 权重** — 逐维度说明评分依据，标注中文母语者常见偏误
3. **评分标准** — 5 级档位（90-100 优秀 → 60以下 需加强），每档有具体描述
4. **JSON 输出格式** — 标准化的 `dimensions.*.score/comment` + `overall` + `feedback` + `suggestions`
5. **注意事项** — 中文评语、鼓励教育理念、只输出 JSON、面向儿童/初学者

### 关键设计点

- **仅基于文本评分:** 输入是语音识别文本（非音频），通过对比参考文本和识别文本的差异推断发音问题
- **不幻想音频质量:** 提示词中明确"语音识别可能存在误差"，引导模型基于文本相似度做合理推断
- **鼓励式评语:** 先肯定 → 再指出问题 → 给出具体可操作建议，适合儿童启蒙场景

---

## License

内部项目，随 card-template 仓库管理。

"""
config.py — 评分服务配置

集中管理 DeepSeek API 连接参数，方便不同环境切换。
"""

# ============================================================
# DeepSeek API 配置
# ============================================================

DEEPSEEK_CONFIG = {
    "api_url": "https://api.deepseek.com/v1/chat/completions",
    "api_key": "sk-686fef4df9c24c4abd637afedcac3c90",
    "model": "deepseek-v4-pro",
    "temperature": 0.3,
    "max_tokens": 4096,
    "timeout": 60,  # 秒
}

# ============================================================
# 评分维度权重
# ============================================================

# 英语单词卡片
WORD_DIMENSIONS = [
    {"key": "pronunciation", "label": "发音准确度", "weight": 0.45,
     "description": "音素发音是否标准，元音和辅音是否清晰准确，重音位置是否正确"},
    {"key": "completeness",   "label": "完整性",     "weight": 0.30,
     "description": "是否完整读出单词，有无漏读音节或多余音节"},
    {"key": "fluency",        "label": "流利度",     "weight": 0.25,
     "description": "发音是否流畅自然，有无不必要的停顿或重复"},
]

# 英语句子卡片
SENTENCE_DIMENSIONS = [
    {"key": "pronunciation", "label": "发音准确度", "weight": 0.30,
     "description": "每个单词的发音是否标准，重点词汇的发音是否清晰准确"},
    {"key": "completeness",   "label": "完整性",     "weight": 0.25,
     "description": "是否完整读出句子中的所有单词，有无遗漏或多余内容"},
    {"key": "fluency",        "label": "流利度",     "weight": 0.25,
     "description": "朗读是否流畅，词与词之间衔接是否自然，有无不必要的停顿"},
    {"key": "intonation",     "label": "语调自然度", "weight": 0.20,
     "description": "语调是否自然，陈述句/感叹句的语调模式是否正确，重读和弱读是否恰当"},
]

# 英语输入句子卡片
INPUT_DIMENSIONS = [
    {"key": "pronunciation", "label": "发音准确度", "weight": 0.28,
     "description": "单词发音是否标准，特殊发音（连读、弱读）是否处理得当"},
    {"key": "completeness",   "label": "完整性",     "weight": 0.20,
     "description": "是否完整读出输入的所有内容，有无遗漏单词或短语"},
    {"key": "fluency",        "label": "流利度",     "weight": 0.22,
     "description": "朗读是否流畅自然，语速是否适中，有无不自然的停顿或重复"},
    {"key": "intonation",     "label": "语调自然度", "weight": 0.18,
     "description": "语调是否符合英语表达习惯，升降调是否自然，句子节奏感如何"},
    {"key": "expression",     "label": "语法与表达", "weight": 0.12,
     "description": "输入的英语句子本身是否语法正确、表达地道（仅作参考）"},
]


def get_dimensions(card_type: str) -> list[dict]:
    """根据卡片类型返回对应的评分维度"""
    mapping = {
        "english_word":     WORD_DIMENSIONS,
        "english_sentence": SENTENCE_DIMENSIONS,
        "english_input":    INPUT_DIMENSIONS,
    }
    return mapping.get(card_type, SENTENCE_DIMENSIONS)

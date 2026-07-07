"""
scoring_service.py — 英语口语评分服务（Python 版）

为 english-word-card、english-sentence-card、english-input-card
提供统一的 DeepSeek API 评分能力。

使用方式:
    import asyncio
    from scoring_service import score

    result = asyncio.run(score(
        card_type="english_word",
        target_text="apple",
        recognized_text="appel"
    ))
    print(result)

返回格式:
    {
        "overall": 85,
        "dimensions": [
            {"key": "pronunciation", "label": "发音准确度", "score": 88, "weight": 0.45, "comment": "..."},
            ...
        ],
        "feedback": "总体评语",
        "highlights": "亮点分析",
        "suggestions": "改进建议",
        "is_fallback": False
    }
"""

import json
import re
import logging
from typing import Optional

import httpx

from config import DEEPSEEK_CONFIG, get_dimensions
from prompts import get_system_prompt, build_user_prompt

logger = logging.getLogger(__name__)


# ============================================================
# 核心评分函数
# ============================================================

async def score(
    card_type: str,
    target_text: str,
    recognized_text: str,
    *,
    api_key: Optional[str] = None,
    api_url: Optional[str] = None,
    model: Optional[str] = None,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    timeout: Optional[int] = None,
) -> dict:
    """
    对用户跟读进行 AI 评分。

    Args:
        card_type: 卡片类型 — 'english_word' | 'english_sentence' | 'english_input'
        target_text: 参考文本（目标单词/句子）
        recognized_text: 语音识别文本（用户实际发音）
        api_key: 可选，覆盖默认 API Key
        api_url: 可选，覆盖默认 API URL
        model: 可选，覆盖默认模型
        temperature: 可选，覆盖默认温度
        max_tokens: 可选，覆盖默认最大 token 数
        timeout: 可选，覆盖默认超时时间（秒）

    Returns:
        评分结果字典，包含 overall、dimensions、feedback、highlights、suggestions

    Raises:
        ValueError: target_text 或 recognized_text 为空
    """
    # 参数校验
    target_text = (target_text or "").strip()
    recognized_text = (recognized_text or "").strip()

    if not target_text:
        raise ValueError("target_text 不能为空")
    if not recognized_text:
        raise ValueError("recognized_text 不能为空")

    # 组装请求
    system_prompt = get_system_prompt(card_type)
    user_prompt = build_user_prompt(card_type, target_text, recognized_text)

    payload = {
        "model": model or DEEPSEEK_CONFIG["model"],
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": temperature if temperature is not None else DEEPSEEK_CONFIG["temperature"],
        "max_tokens": max_tokens or DEEPSEEK_CONFIG["max_tokens"],
        "response_format": {"type": "json_object"},
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key or DEEPSEEK_CONFIG['api_key']}",
    }

    # 发起请求
    _timeout = timeout or DEEPSEEK_CONFIG["timeout"]
    try:
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(_timeout, connect=10.0),
            http2=False,
        ) as client:
            response = await client.post(
                api_url or DEEPSEEK_CONFIG["api_url"],
                json=payload,
                headers=headers,
            )
            response.raise_for_status()
            data = response.json()
    except httpx.TimeoutException:
        logger.warning("DeepSeek API 请求超时，使用降级评分")
        return _fallback_result(card_type, reason="API 请求超时")
    except httpx.HTTPStatusError as e:
        logger.warning(f"DeepSeek API 返回错误: {e.response.status_code}，使用降级评分")
        return _fallback_result(card_type, reason=f"API 返回 {e.response.status_code}")
    except Exception as e:
        logger.warning(f"DeepSeek API 调用异常: {e}，使用降级评分")
        return _fallback_result(card_type, reason=str(e))

    # 解析响应
    try:
        return _parse_response(data, card_type)
    except Exception as e:
        logger.warning(f"响应解析失败: {e}，使用降级评分")
        return _fallback_result(card_type, reason=f"解析失败: {e}")


# ============================================================
# 内部辅助函数
# ============================================================

def _parse_response(api_data: dict, card_type: str) -> dict:
    """解析 DeepSeek API 返回的 JSON 评分结果"""
    dims = get_dimensions(card_type)

    # 提取 content
    try:
        content = api_data["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError):
        return _fallback_result(card_type, reason="API 响应格式异常")

    # 尝试从 markdown 代码块中提取 JSON
    json_match = re.search(r"```(?:json)?\s*\n?([\s\S]*?)\n?```", content)
    json_str = json_match.group(1) if json_match else content

    try:
        raw = json.loads(json_str)
    except json.JSONDecodeError as e:
        tail = json_str[-80:] if len(json_str) > 80 else json_str
        logger.warning(f"JSON 解析失败: {e} | 末尾内容: ...{tail}")
        return _fallback_result(card_type, reason=f"JSON 无效 (可能被截断): {e}")

    # 提取总体分
    overall = raw.get("overall", 0)
    if isinstance(overall, (int, float)):
        overall = max(0, min(100, round(overall)))
    else:
        overall = 0

    # 构建各维度结果
    dimensions = []
    total_weighted = 0.0
    total_weight = 0.0

    raw_dims = raw.get("dimensions", {})

    for dim in dims:
        dim_data = raw_dims.get(dim["key"], {})
        score_val = dim_data.get("score", 0)
        if isinstance(score_val, (int, float)):
            score_val = max(0, min(100, round(score_val)))
        else:
            score_val = 0

        comment = dim_data.get("comment", "")

        dimensions.append({
            "key": dim["key"],
            "label": dim["label"],
            "score": score_val,
            "weight": dim["weight"],
            "comment": comment,
        })

        total_weighted += score_val * dim["weight"]
        total_weight += dim["weight"]

    # 如果 overall 为 0，用加权平均计算
    if overall == 0 and total_weight > 0:
        overall = round(total_weighted / total_weight)

    return {
        "overall": overall,
        "dimensions": dimensions,
        "feedback": raw.get("feedback", "") or _default_feedback(overall),
        "highlights": raw.get("highlights", ""),
        "suggestions": raw.get("suggestions", ""),
        "is_fallback": False,
    }


def _fallback_result(card_type: str, reason: str = "") -> dict:
    """API 不可用时的降级结果"""
    dims = get_dimensions(card_type)
    dimensions = [
        {
            "key": dim["key"],
            "label": dim["label"],
            "score": 0,
            "weight": dim["weight"],
            "comment": f"评分服务暂时不可用（{reason}）" if reason else "评分服务暂时不可用",
        }
        for dim in dims
    ]
    return {
        "overall": 0,
        "dimensions": dimensions,
        "feedback": "评分服务暂时不可用，请稍后重试。",
        "highlights": "",
        "suggestions": "请检查网络连接后重试。",
        "is_fallback": True,
        "fallback_reason": reason,
    }


def _default_feedback(score: int) -> str:
    """根据分数返回默认评语"""
    if score >= 90:
        return "太棒了！你的发音非常标准，继续加油！🌟"
    if score >= 80:
        return "读得很好！发音比较标准，再注意一下细节就更完美了！👍"
    if score >= 70:
        return "不错哦！基本读出来了，多练习几次会更好！💪"
    if score >= 60:
        return "还可以，继续努力！建议多听几遍范读再跟读。📖"
    return "别灰心！多听多读，每一次练习都会进步的！🌈"


# ============================================================
# CLI 入口
# ============================================================

if __name__ == "__main__":
    import sys
    import asyncio

    async def main():
        if len(sys.argv) < 4:
            print("用法: python scoring_service.py <card_type> <target_text> <recognized_text>")
            print("示例: python scoring_service.py english_word apple appel")
            print()
            print("card_type 可选值: english_word | english_sentence | english_input")
            sys.exit(1)

        card_type = sys.argv[1]
        target = sys.argv[2]
        recognized = sys.argv[3]

        result = await score(card_type, target, recognized)
        print(json.dumps(result, ensure_ascii=False, indent=2))

    asyncio.run(main())

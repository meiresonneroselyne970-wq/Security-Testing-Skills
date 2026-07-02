"""
server.py — 英语口语评分 HTTP API

启动方式:
    cd english-scoring/
    pip install fastapi uvicorn
    python server.py

API 端点:
    POST /api/score  →  AI 评分
    GET  /api/health →  健康检查
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

from scoring_service import score

app = FastAPI(
    title="English Scoring API",
    description="英语口语 AI 评分服务 — 为 english-word / english-sentence / english-input 三类卡片提供多维度发音评分",
    version="1.0.0",
)

# CORS — 允许卡片页面跨域调用
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# 请求/响应模型
# ============================================================

class ScoreRequest(BaseModel):
    card_type: str = Field(
        ...,
        description="卡片类型",
        examples=["english_word"],
        pattern=r"^(english_word|english_sentence|english_input)$",
    )
    target_text: str = Field(
        ...,
        min_length=1,
        description="参考文本（目标单词或句子）",
        examples=["apple"],
    )
    recognized_text: str = Field(
        ...,
        min_length=1,
        description="语音识别文本（用户实际发音）",
        examples=["appel"],
    )


class ScoreResponse(BaseModel):
    overall: int = Field(description="综合得分 0-100")
    dimensions: list = Field(description="各维度评分详情")
    feedback: str = Field(description="总体评语")
    highlights: str = Field(description="亮点分析")
    suggestions: str = Field(description="改进建议")
    is_fallback: bool = Field(description="是否为降级结果")


# ============================================================
# API 端点
# ============================================================

@app.post("/api/score", response_model=ScoreResponse)
async def score_endpoint(req: ScoreRequest):
    """AI 多维度评分"""
    try:
        result = await score(
            card_type=req.card_type,
            target_text=req.target_text,
            recognized_text=req.recognized_text,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"评分服务异常: {e}")


@app.get("/api/health")
async def health():
    """健康检查"""
    return {"status": "ok", "service": "english-scoring"}


# ============================================================
# 启动
# ============================================================

if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host="0.0.0.0",
        port=8800,
        reload=True,
        log_level="info",
    )

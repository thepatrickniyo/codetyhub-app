"""
code_review_routes.py
---------------------
FastAPI router for the ML-driven code review and Verified Skill Score (VSS)
computation via CodeBERT.

Endpoints:
  POST /code-review/evaluate      — Evaluate a code submission and compute VSS
  GET  /code-review/leaderboard   — Return the current VSS leaderboard
  GET  /code-review/rubric        — Return the VSS rubric and weights
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi import APIRouter, HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from ML.api.schemas import CodeReviewRequest, CodeReviewResponse
from ML.code_review.codebert_evaluator import (
    CodeBertEvaluator,
    RUBRIC_WEIGHTS,
    _REDIS_SORTED_SET,
)

router = APIRouter(prefix="/code-review", tags=["Code Review & VSS"])

# Singleton evaluator (loads API key from env)
_evaluator: CodeBertEvaluator | None = None


def get_evaluator() -> CodeBertEvaluator:
    global _evaluator
    if _evaluator is None:
        api_key = os.getenv("HUGGINGFACE_API_KEY")
        _evaluator = CodeBertEvaluator(api_key=api_key)
    return _evaluator


@router.post("/evaluate", response_model=CodeReviewResponse)
async def evaluate_code(request: CodeReviewRequest) -> CodeReviewResponse:
    """
    Evaluate a student's code submission using CodeBERT and compute VSS.

    The VSS is computed across 4 rubric dimensions:
      - code_correctness     (35%)
      - structural_elegance  (25%)
      - contextual_alignment (25%)
      - documentation        (15%)

    The resulting score is used to update the Redis Sorted Set leaderboard
    (ZADD), instantly updating the student's position on the employer-visible
    talent marketplace.
    """
    if not request.code_text.strip():
        raise HTTPException(status_code=422, detail="Code submission cannot be empty.")

    evaluator = get_evaluator()

    try:
        result = evaluator.evaluate(
            student_id=request.student_id,
            skill_node=request.skill_node,
            code_text=request.code_text,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Evaluation failed: {str(e)}")

    return CodeReviewResponse(
        student_id=result.student_id,
        skill_node=result.skill_node,
        vss=result.vss,
        dimension_scores=result.dimension_scores,
        feedback=result.feedback,
        submission_hash=result.submission_hash,
        leaderboard_rank=result.leaderboard_rank,
    )


@router.get("/leaderboard")
async def get_leaderboard(limit: int = 20) -> dict:
    """
    Return the current VSS leaderboard from the Redis Sorted Set.

    In production, this queries: redis_client.zrevrangebyscore("leaderboard:vss", ...)
    """
    sorted_entries = sorted(_REDIS_SORTED_SET.items(), key=lambda x: x[1], reverse=True)
    top = sorted_entries[:limit]

    return {
        "total_students_ranked": len(_REDIS_SORTED_SET),
        "leaderboard": [
            {
                "rank": rank + 1,
                "student_id": student_id,
                "vss": round(vss, 2),
            }
            for rank, (student_id, vss) in enumerate(top)
        ],
    }


@router.get("/rubric")
async def get_rubric() -> dict:
    """Return the VSS evaluation rubric and dimension weights."""
    return {
        "rubric_dimensions": {
            dim: {
                "weight": weight,
                "description": _RUBRIC_DESCRIPTIONS.get(dim, ""),
                "weight_pct": f"{weight * 100:.0f}%",
            }
            for dim, weight in RUBRIC_WEIGHTS.items()
        },
        "vss_range": {"min": 0.0, "max": 100.0},
        "model": "microsoft/codebert-base (fine-tuned)",
        "note": "VSS automatically updates the Redis Sorted Set leaderboard (ZADD).",
    }


_RUBRIC_DESCRIPTIONS = {
    "code_correctness": (
        "Does the code correctly solve the stated problem? "
        "Assessed via execution pathways and expected output alignment."
    ),
    "structural_elegance": (
        "Modularity, DRY principles, naming conventions, "
        "function decomposition, and overall code readability."
    ),
    "contextual_alignment": (
        "How well does the code demonstrate mastery of the target skill node? "
        "Assessed against the module's learning objectives rubric."
    ),
    "documentation": (
        "Quality and completeness of inline comments, docstrings, "
        "type hints, and README/usage instructions."
    ),
}

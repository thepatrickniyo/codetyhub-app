"""
gamification_routes.py
-----------------------
FastAPI router for the ML-Driven Gamification & Dropout Prediction module.

Endpoints:
  POST /gamification/risk     — Run XGBoost dropout risk prediction for a student
  POST /gamification/batch    — Run daily batch risk assessment for multiple students
  GET  /gamification/features — Return the 34 feature names and descriptions
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from ML.api.schemas import (
    GamificationRiskRequest,
    GamificationRiskResponse,
    InterventionSchema,
)
from ML.gamification.dropout_predictor import DropoutPredictor
from ML.gamification.feature_engineering import FEATURE_NAMES

router = APIRouter(prefix="/gamification", tags=["Gamification & Dropout Prediction"])

# Singleton predictor
_predictor: DropoutPredictor | None = None


def get_predictor() -> DropoutPredictor:
    global _predictor
    if _predictor is None:
        _predictor = DropoutPredictor()
    return _predictor


def _request_to_student_dict(req: GamificationRiskRequest) -> dict:
    """Convert the API request schema to the internal student dict format."""
    return {
        "student_id": req.student_id,
        "ikp": req.ikp.proficiency_scores,
        "engagement": {
            "current_streak": req.engagement.current_streak,
            "streak_delta_7d": req.engagement.streak_delta_7d,
            "total_xp": req.engagement.total_xp,
            "xp_trend_slope": req.engagement.xp_trend_slope,
            "leaderboard_checks_30d": req.engagement.leaderboard_checks_30d,
            "challenge_refusals_30d": req.engagement.challenge_refusals_30d,
            "sessions_per_week": req.engagement.sessions_per_week,
            "avg_session_minutes": req.engagement.avg_session_minutes,
        },
        "interactions": [
            {
                "module_name": i.module_name,
                "score": i.score,
                "attempts": i.attempts,
                "time_minutes": i.time_minutes,
                "completed": i.completed,
            }
            for i in req.interactions
        ],
    }


@router.post("/risk", response_model=GamificationRiskResponse)
async def predict_risk(request: GamificationRiskRequest) -> GamificationRiskResponse:
    """
    Predict dropout risk for a single student.

    The XGBoost model outputs a probability in [0.0, 1.0]:
      • < 0.35  → LOW  — standard pacing, no intervention
      • 0.35–0.65 → MEDIUM — light nudges
      • ≥ 0.65  → HIGH  — active gamification interventions triggered

    The response includes a list of personalised interventions to push to
    the mobile app (Streak Recovery Tokens, bonus XP challenges, peer room
    invitations).
    """
    predictor = get_predictor()
    student_dict = _request_to_student_dict(request)

    try:
        result = predictor.predict(student_dict)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

    interventions = [
        InterventionSchema(
            type=iv.type,
            title=iv.title,
            description=iv.description,
            payload=iv.payload,
        )
        for iv in result.interventions
    ]

    return GamificationRiskResponse(
        student_id=result.student_id,
        risk_score=result.risk_score,
        risk_band=result.risk_band.value,
        interventions=interventions,
        top_risk_factors=result.top_risk_factors,
    )


class BatchRiskRequest(GamificationRiskRequest):
    """Used only for type hints — batch sends a list of requests."""
    pass


@router.post("/batch")
async def predict_risk_batch(requests: list[GamificationRiskRequest]) -> list[dict[str, Any]]:
    """
    Run daily dropout risk assessment for a batch of students.

    Intended to be called by the scheduled daily pipeline cron job.
    Returns a summary array sorted by descending risk score.
    """
    if not requests:
        return []

    predictor = get_predictor()
    results = []

    for req in requests:
        student_dict = _request_to_student_dict(req)
        result = predictor.predict(student_dict)
        results.append({
            "student_id": result.student_id,
            "risk_score": result.risk_score,
            "risk_band": result.risk_band.value,
            "intervention_count": len(result.interventions),
        })

    results.sort(key=lambda x: x["risk_score"], reverse=True)
    return results


@router.get("/features")
async def list_features() -> dict:
    """Return the 34 engineered feature names used by the dropout predictor."""
    categories = {
        "A_Academic_Performance": FEATURE_NAMES[0:8],
        "B_Engagement_Activity":  FEATURE_NAMES[8:16],
        "C_Gamification_Signals": FEATURE_NAMES[16:23],
        "D_Progression_Signals":  FEATURE_NAMES[23:28],
        "E_Social_Peer_Signals":  FEATURE_NAMES[28:32],
        "F_Temporal_Patterns":    FEATURE_NAMES[32:34],
    }
    return {
        "total_features": len(FEATURE_NAMES),
        "feature_names": FEATURE_NAMES,
        "categories": categories,
        "risk_thresholds": {
            "low_risk_max": 0.35,
            "medium_risk_range": [0.35, 0.65],
            "high_risk_min": 0.65,
        },
    }

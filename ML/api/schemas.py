"""
schemas.py
----------
Pydantic v2 request and response schemas for all CodetyHub ML API endpoints.
"""

from __future__ import annotations

from typing import Any
from pydantic import BaseModel, Field


# ── Shared ─────────────────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "CodetyHub ML API"
    version: str = "1.0.0"


# ── Pathway Recommendation ─────────────────────────────────────────────────────

class IKP(BaseModel):
    """Individual Knowledge Profile — maps skill IDs to proficiency scores."""
    proficiency_scores: dict[str, float] = Field(
        ...,
        description="Maps skill node IDs to proficiency scores in [0.0, 1.0].",
        example={
            "python_basics": 0.90,
            "data_types": 0.85,
            "control_flow": 0.80,
            "linear_regression": 0.20,
        },
    )


class PathwayRecommendRequest(BaseModel):
    student_id: str = Field(..., description="Unique student identifier.")
    ikp: IKP
    top_n: int = Field(5, ge=1, le=20, description="Max recommendations to return.")
    include_collaborative: bool = Field(
        True,
        description="If true, merge rule-based results with collaborative filtering.",
    )


class SkillRecommendation(BaseModel):
    skill_id: str
    label: str
    rule_based_priority: float | None = None
    collaborative_confidence: float | None = None
    hybrid_score: float


class PathwayRecommendResponse(BaseModel):
    student_id: str
    mastered: list[str]
    in_progress: list[str]
    recommendations: list[SkillRecommendation]
    total_skills: int
    completion_pct: float


# ── Gamification / Dropout Prediction ─────────────────────────────────────────

class EngagementMetrics(BaseModel):
    current_streak: int = 0
    streak_delta_7d: int = 0
    total_xp: float = 0.0
    xp_trend_slope: float = 0.0
    leaderboard_checks_30d: int = 0
    challenge_refusals_30d: int = 0
    sessions_per_week: float = 0.0
    avg_session_minutes: float = 0.0


class StudentInteraction(BaseModel):
    module_name: str
    score: float = Field(ge=0.0, le=1.0)
    attempts: int = Field(ge=1)
    time_minutes: float
    completed: bool


class GamificationRiskRequest(BaseModel):
    student_id: str
    ikp: IKP
    engagement: EngagementMetrics
    interactions: list[StudentInteraction] = []


class InterventionSchema(BaseModel):
    type: str
    title: str
    description: str
    payload: dict[str, Any] = {}


class GamificationRiskResponse(BaseModel):
    student_id: str
    risk_score: float = Field(description="Dropout probability [0.0, 1.0]")
    risk_band: str = Field(description="LOW | MEDIUM | HIGH")
    interventions: list[InterventionSchema]
    top_risk_factors: list[list[Any]] = Field(
        description="Top 5 [feature_name, importance_weight] pairs"
    )


# ── Code Review / VSS ──────────────────────────────────────────────────────────

class CodeReviewRequest(BaseModel):
    student_id: str
    skill_node: str = Field(
        ...,
        description="Knowledge graph node this submission targets.",
        example="linear_regression",
    )
    code_text: str = Field(..., description="Raw source code as a string.")


class CodeReviewResponse(BaseModel):
    student_id: str
    skill_node: str
    vss: float = Field(description="Verified Skill Score [0.0, 100.0]")
    dimension_scores: dict[str, float]
    feedback: dict[str, str]
    submission_hash: str
    leaderboard_rank: int | None

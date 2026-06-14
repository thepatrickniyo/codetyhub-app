"""
dropout_predictor.py
---------------------
Inference pipeline for the CodetyHub Behavioural Engagement Predictor.

Given a student profile, this module:
  1. Extracts the 34 engineered features.
  2. Runs them through the trained XGBoost model.
  3. Returns a dropout risk probability in [0.0, 1.0].
  4. Applies the risk-band thresholds to decide which gamification
     intervention (if any) to trigger.

Risk Bands (as specified in the brief):
  • Low Risk    (< 0.35):  Maintain standard pacing. Keep rewards anchored to
                            skill-verified assignments.
  • Medium Risk (0.35–0.65): Light nudges — streak reminders, leaderboard
                              highlights.
  • High Risk   (≥ 0.65):  Active intervention — Streak Recovery Token, bonus
                            XP challenge, automated peer study room invitation.

Usage:
    from ML.gamification.dropout_predictor import DropoutPredictor

    predictor = DropoutPredictor()
    result = predictor.predict(student_profile)

    print(result.risk_score)      # e.g. 0.78
    print(result.risk_band)       # "HIGH"
    print(result.interventions)   # List of triggered interventions
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from ML.gamification.feature_engineering import extract_features, FEATURE_NAMES

MODEL_PATH = Path(__file__).parent / "xgb_dropout_model.json"
FEATURE_META_PATH = Path(__file__).parent / "feature_meta.json"

LOW_RISK_MAX = 0.35
HIGH_RISK_MIN = 0.65

# ── XGBoost import ────────────────────────────────────────────────────────────
try:
    import xgboost as xgb
    _XGB_AVAILABLE = True
except ImportError:
    _XGB_AVAILABLE = False


class RiskBand(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


@dataclass
class Intervention:
    """A single gamification intervention triggered by high risk."""
    type: str
    title: str
    description: str
    payload: dict = field(default_factory=dict)


@dataclass
class PredictionResult:
    """
    Full output from DropoutPredictor.predict().

    Attributes:
        student_id:    Identifier of the student.
        risk_score:    Float in [0.0, 1.0] — higher means more likely to drop out.
        risk_band:     LOW / MEDIUM / HIGH classification.
        interventions: List of gamification actions to trigger (empty if low risk).
        feature_vector: The 34 features used for this prediction.
        top_risk_factors: Top 5 features most influencing the high risk score.
    """
    student_id: str
    risk_score: float
    risk_band: RiskBand
    interventions: list[Intervention]
    feature_vector: list[float]
    top_risk_factors: list[tuple[str, float]]


class DropoutPredictor:
    """
    XGBoost-based dropout risk inference service.

    Falls back to a heuristic scorer if the trained model file is not present
    (useful for CI/CD pipelines before the first training run).
    """

    def __init__(self, model_path: str | Path = MODEL_PATH):
        self.model_path = Path(model_path)
        self._model = None
        self._feature_importances: np.ndarray | None = None
        self._load_model()

    def _load_model(self) -> None:
        """Load trained XGBoost model from disk, or log a warning if missing."""
        if not _XGB_AVAILABLE:
            print("[DropoutPredictor] xgboost not installed — using heuristic fallback.")
            return

        if not self.model_path.exists():
            print(f"[DropoutPredictor] Model not found at {self.model_path}. "
                  "Run xgb_model_trainer.py first. Using heuristic fallback.")
            return

        try:
            self._model = xgb.XGBClassifier()
            self._model.load_model(str(self.model_path))
            self._feature_importances = self._model.feature_importances_
            print(f"[DropoutPredictor] Model loaded from {self.model_path}")
        except Exception as e:
            print(f"[DropoutPredictor] Failed to load model: {e}. Using heuristic fallback.")
            self._model = None

    def _heuristic_risk(self, features: list[float]) -> float:
        """
        Deterministic heuristic fallback when the model is unavailable.
        Combines key engagement signals into a risk estimate.
        """
        feat = dict(zip(FEATURE_NAMES, features))
        score = 0.0
        # Low XP trend → higher risk
        if feat["xp_trend_slope"] < 0:
            score += 0.25
        # Short streak → higher risk
        if feat["login_streak_current"] < 3:
            score += 0.20
        # Low completion rate
        if feat["completion_rate"] < 0.4:
            score += 0.20
        # High challenge refusals
        if feat["challenge_refusals_30d"] > 5:
            score += 0.15
        # Low leaderboard engagement
        if feat["leaderboard_checks_30d"] < 3:
            score += 0.10
        # Low sessions per week
        if feat["sessions_per_week"] < 2.0:
            score += 0.10
        return min(score, 0.99)

    def _get_top_risk_factors(
        self,
        features: list[float],
        top_n: int = 5,
    ) -> list[tuple[str, float]]:
        """Return top N feature names weighted by model importance × feature value."""
        if self._feature_importances is None:
            return []
        weighted = [
            (name, float(self._feature_importances[i]) * abs(features[i]))
            for i, name in enumerate(FEATURE_NAMES)
        ]
        return sorted(weighted, key=lambda x: x[1], reverse=True)[:top_n]

    def _build_interventions(
        self,
        risk_band: RiskBand,
        student: dict,
    ) -> list[Intervention]:
        """
        Construct the list of interventions appropriate for the risk band.

        Args:
            risk_band: Classified risk level.
            student:   Full student profile (for personalised content).

        Returns:
            List of Intervention objects.
        """
        if risk_band == RiskBand.LOW:
            return []

        interventions = []

        if risk_band == RiskBand.MEDIUM:
            interventions.append(Intervention(
                type="streak_reminder",
                title="Keep Your Streak Alive! 🔥",
                description=(
                    f"You're on a {student.get('engagement', {}).get('current_streak', 0)}-day "
                    "streak. Log in tomorrow to keep it going!"
                ),
                payload={"push_notification": True},
            ))
            interventions.append(Intervention(
                type="leaderboard_highlight",
                title="Check the Leaderboard",
                description="You've moved up 3 positions this week — see where you stand!",
                payload={"badge": "climber"},
            ))

        if risk_band == RiskBand.HIGH:
            # Identify the student's strongest onboarding skill for targeted challenge
            ikp = student.get("ikp", {})
            best_skill = max(ikp, key=lambda k: ikp[k]) if ikp else "python_basics"
            best_score = ikp.get(best_skill, 0.0)

            interventions.append(Intervention(
                type="streak_recovery_token",
                title="Streak Recovery Token 🛡️",
                description=(
                    "We know life gets busy! Use this token to protect your streak "
                    "for one day — no questions asked."
                ),
                payload={"token_type": "streak_shield", "expires_in_hours": 48},
            ))
            interventions.append(Intervention(
                type="bonus_xp_challenge",
                title=f"Quick Win: {best_skill.replace('_', ' ').title()} Bonus 🎯",
                description=(
                    f"You scored {best_score:.0%} in {best_skill.replace('_', ' ').title()} "
                    "— crush this 10-min bonus challenge for 200 XP!"
                ),
                payload={
                    "skill_target": best_skill,
                    "xp_reward": 200,
                    "time_limit_minutes": 10,
                },
            ))
            interventions.append(Intervention(
                type="peer_study_room_invite",
                title="Join a Study Room 👥",
                description=(
                    "3 students near your level are studying right now. "
                    "Join them for a 30-min co-learning session!"
                ),
                payload={"auto_match": True, "session_duration_minutes": 30},
            ))

        return interventions

    def predict(self, student: dict[str, Any]) -> PredictionResult:
        """
        Run dropout risk inference for a single student.

        Args:
            student: Student profile dict (from mock_students or PostgreSQL).

        Returns:
            PredictionResult with risk score, band, and interventions.
        """
        student_id = student.get("student_id", "unknown")
        features = extract_features(student)

        # ── Inference ──────────────────────────────────────────────────────────
        if self._model is not None:
            X = np.array(features, dtype=np.float32).reshape(1, -1)
            risk_score = float(self._model.predict_proba(X)[0, 1])
        else:
            risk_score = self._heuristic_risk(features)

        # ── Risk band classification ───────────────────────────────────────────
        if risk_score < LOW_RISK_MAX:
            risk_band = RiskBand.LOW
        elif risk_score < HIGH_RISK_MIN:
            risk_band = RiskBand.MEDIUM
        else:
            risk_band = RiskBand.HIGH

        top_risk_factors = self._get_top_risk_factors(features)
        interventions = self._build_interventions(risk_band, student)

        return PredictionResult(
            student_id=student_id,
            risk_score=round(risk_score, 4),
            risk_band=risk_band,
            interventions=interventions,
            feature_vector=features,
            top_risk_factors=top_risk_factors,
        )

    def predict_batch(self, students: list[dict]) -> list[PredictionResult]:
        """
        Run inference for a batch of students (daily pipeline).

        Args:
            students: List of student profile dicts.

        Returns:
            List of PredictionResult objects.
        """
        return [self.predict(s) for s in students]


if __name__ == "__main__":
    from ML.data.mock_students import generate_students

    students = generate_students()
    predictor = DropoutPredictor()

    print("=== Batch Inference (first 5 students) ===")
    results = predictor.predict_batch(students[:5])
    for r in results:
        print(f"\n{r.student_id}")
        print(f"  Risk Score: {r.risk_score:.4f}  →  {r.risk_band.value}")
        if r.interventions:
            print(f"  Interventions ({len(r.interventions)}):")
            for iv in r.interventions:
                print(f"    • [{iv.type}] {iv.title}")
        else:
            print("  No interventions needed.")

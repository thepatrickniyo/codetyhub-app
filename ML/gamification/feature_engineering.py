"""
feature_engineering.py
-----------------------
Extracts the 34 behavioural engagement features from a student's platform logs
for use by the XGBoost dropout predictor.

Feature categories (total = 34):
  A. Academic Performance (8 features)
  B. Engagement / Activity (8 features)
  C. Gamification Signals (7 features)
  D. Progression Signals (5 features)
  E. Social / Peer Signals (4 features)
  F. Temporal Patterns (2 features)

Usage:
    from ML.gamification.feature_engineering import extract_features

    feature_vector = extract_features(student_profile)
    # Returns a list of 34 float values in canonical order
"""

from __future__ import annotations

import math
import numpy as np
from typing import Any


# ── Feature names in canonical order (34 total) ───────────────────────────────
FEATURE_NAMES: list[str] = [
    # A. Academic Performance (8)
    "avg_module_score",
    "score_std_dev",
    "completion_rate",
    "avg_attempts_per_module",
    "failed_module_count",
    "avg_time_per_module_minutes",
    "min_module_score",
    "score_trend_slope",

    # B. Engagement / Activity (8)
    "sessions_per_week",
    "avg_session_minutes",
    "days_since_last_login",
    "total_active_days_30d",
    "login_streak_current",
    "login_streak_delta_7d",
    "xp_total",
    "xp_trend_slope",

    # C. Gamification Signals (7)
    "leaderboard_checks_30d",
    "challenge_acceptance_rate",
    "challenge_refusals_30d",
    "badge_unlock_count",
    "peer_study_room_joins",
    "streak_recovery_token_used",
    "bonus_challenge_completions",

    # D. Progression Signals (5)
    "skills_mastered_count",
    "skills_in_progress_count",
    "skills_unlocked_not_started",
    "pathway_depth_reached",
    "ikp_mean_proficiency",

    # E. Social / Peer Signals (4)
    "peer_messages_sent_30d",
    "peer_messages_received_30d",
    "collaborative_sessions_30d",
    "mentor_session_count",

    # F. Temporal Patterns (2)
    "preferred_study_hour",
    "weekend_activity_ratio",
]

assert len(FEATURE_NAMES) == 34, f"Expected 34 features, got {len(FEATURE_NAMES)}"


def _safe_div(a: float, b: float, default: float = 0.0) -> float:
    return a / b if b != 0 else default


def extract_features(student: dict[str, Any]) -> list[float]:
    """
    Extract the 34 engagement features from a student profile dict.

    The input dict follows the schema produced by mock_students.generate_students().
    In production, this dict would be assembled from PostgreSQL + Redis logs.

    Args:
        student: Student profile dict with keys: ikp, engagement, interactions,
                 and optional gamification / social sub-dicts.

    Returns:
        List of 34 float values in the order defined by FEATURE_NAMES.
    """
    ikp: dict = student.get("ikp", {})
    eng: dict = student.get("engagement", {})
    interactions: list = student.get("interactions", [])
    gamif: dict = student.get("gamification", {})
    social: dict = student.get("social", {})

    # ── A. Academic Performance ───────────────────────────────────────────────
    scores = [log["score"] for log in interactions if "score" in log]
    times = [log["time_minutes"] for log in interactions if "time_minutes" in log]
    attempts_list = [log["attempts"] for log in interactions if "attempts" in log]
    completions = [log.get("completed", False) for log in interactions]

    avg_score = float(np.mean(scores)) if scores else 0.0
    score_std = float(np.std(scores)) if len(scores) > 1 else 0.0
    completion_rate = _safe_div(sum(completions), len(completions))
    avg_attempts = float(np.mean(attempts_list)) if attempts_list else 0.0
    failed_count = float(sum(1 for s in scores if s < 0.50))
    avg_time = float(np.mean(times)) if times else 0.0
    min_score = float(min(scores)) if scores else 0.0

    # Score trend: linear regression slope over interaction order
    if len(scores) >= 2:
        x = np.arange(len(scores), dtype=float)
        score_trend = float(np.polyfit(x, scores, 1)[0])
    else:
        score_trend = 0.0

    # ── B. Engagement / Activity ──────────────────────────────────────────────
    sessions_per_week = float(eng.get("sessions_per_week", 0.0))
    avg_session_min = float(eng.get("avg_session_minutes", 0.0))
    days_since_login = float(student.get("days_since_last_login", 0))
    total_active_30d = float(eng.get("total_active_days_30d",
                             min(30, int(sessions_per_week * 4))))
    streak = float(eng.get("current_streak", 0))
    streak_delta = float(eng.get("streak_delta_7d", 0))
    xp_total = float(eng.get("total_xp", 0))
    xp_trend = float(eng.get("xp_trend_slope", 0.0))

    # ── C. Gamification Signals ───────────────────────────────────────────────
    lb_checks = float(eng.get("leaderboard_checks_30d", 0))
    challenge_refusals = float(eng.get("challenge_refusals_30d", 0))
    challenges_total = float(gamif.get("challenges_total", max(1, challenge_refusals + 2)))
    challenge_accepted = challenges_total - challenge_refusals
    challenge_acceptance_rate = _safe_div(challenge_accepted, challenges_total)
    badge_count = float(gamif.get("badge_unlock_count", 0))
    peer_room_joins = float(gamif.get("peer_study_room_joins", 0))
    streak_token_used = float(gamif.get("streak_recovery_token_used", 0))
    bonus_completions = float(gamif.get("bonus_challenge_completions", 0))

    # ── D. Progression Signals ────────────────────────────────────────────────
    mastered_count = float(sum(1 for v in ikp.values() if v >= 0.65))
    in_progress_count = float(sum(1 for v in ikp.values() if 0.20 <= v < 0.65))
    unlocked_not_started = float(sum(1 for v in ikp.values() if v < 0.20))
    pathway_depth = float(student.get("pathway_depth_reached", mastered_count))
    ikp_mean = float(np.mean(list(ikp.values()))) if ikp else 0.0

    # ── E. Social / Peer Signals ──────────────────────────────────────────────
    messages_sent = float(social.get("peer_messages_sent_30d", 0))
    messages_received = float(social.get("peer_messages_received_30d", 0))
    collab_sessions = float(social.get("collaborative_sessions_30d", 0))
    mentor_sessions = float(social.get("mentor_session_count", 0))

    # ── F. Temporal Patterns ──────────────────────────────────────────────────
    preferred_hour = float(student.get("preferred_study_hour", 20))  # 0–23
    weekend_ratio = float(student.get("weekend_activity_ratio", 0.3))  # [0,1]

    features = [
        # A
        avg_score, score_std, completion_rate, avg_attempts,
        failed_count, avg_time, min_score, score_trend,
        # B
        sessions_per_week, avg_session_min, days_since_login, total_active_30d,
        streak, streak_delta, xp_total, xp_trend,
        # C
        lb_checks, challenge_acceptance_rate, challenge_refusals, badge_count,
        peer_room_joins, streak_token_used, bonus_completions,
        # D
        mastered_count, in_progress_count, unlocked_not_started, pathway_depth,
        ikp_mean,
        # E
        messages_sent, messages_received, collab_sessions, mentor_sessions,
        # F
        preferred_hour, weekend_ratio,
    ]

    assert len(features) == 34, f"Feature count mismatch: {len(features)}"
    return [float(f) for f in features]


def extract_feature_matrix(students: list[dict]) -> np.ndarray:
    """
    Extract features for all students into a 2D numpy array.

    Args:
        students: List of student profile dicts.

    Returns:
        np.ndarray of shape (N, 34).
    """
    rows = [extract_features(s) for s in students]
    return np.array(rows, dtype=np.float32)


if __name__ == "__main__":
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from ML.data.mock_students import generate_students

    students = generate_students()
    X = extract_feature_matrix(students)
    print(f"Feature matrix shape: {X.shape}")
    print(f"Feature names ({len(FEATURE_NAMES)}): {FEATURE_NAMES}")
    print(f"\nSample features for student 0:")
    for name, val in zip(FEATURE_NAMES, X[0]):
        print(f"  {name:<40} {val:.4f}")

"""
mock_students.py
----------------
Generates 200 synthetic student profiles for testing the CodetyHub ML pipeline.

Each profile contains:
  - Individual Knowledge Profile (IKP): proficiency scores [0.0–1.0] per STEM skill
  - Interaction logs: module completions, scores, attempts, time-spent
  - Engagement metrics: login streaks, XP, leaderboard checks, challenge refusals
  - Dropout risk label (0 = retained, 1 = dropped out) derived from heuristics

Usage:
    from ML.data.mock_students import generate_students, generate_interaction_matrix
"""

import random
import json
import numpy as np
from datetime import datetime, timedelta

# ── Skill catalogue (matches nodes in the DAG) ───────────────────────────────
SKILL_NODES = [
    "python_basics",
    "data_types",
    "control_flow",
    "functions_scope",
    "oop_fundamentals",
    "file_io",
    "numpy_basics",
    "pandas_basics",
    "data_visualisation",
    "statistics_fundamentals",
    "probability_theory",
    "linear_algebra_basics",
    "matrix_multiplication",
    "calculus_intro",
    "gradient_descent",
    "linear_regression",
    "logistic_regression",
    "decision_trees",
    "random_forests",
    "svd_factorisation",
    "neural_network_basics",
    "backpropagation",
    "cnn_fundamentals",
    "nlp_basics",
    "tokenisation",
    "transformers_intro",
    "fine_tuning_llms",
    "sql_basics",
    "database_design",
    "api_fundamentals",
    "docker_basics",
    "cloud_deployment",
]

N_STUDENTS = 200
N_MODULES = len(SKILL_NODES)

random.seed(42)
np.random.seed(42)


def _generate_ikp(risk_level: float) -> dict:
    """
    Generate an Individual Knowledge Profile.
    High-risk students tend to have more uneven/low proficiency scores.
    """
    ikp = {}
    for skill in SKILL_NODES:
        if risk_level > 0.65:
            # High-risk: patchy knowledge with more low scores
            score = round(float(np.random.beta(1.5, 3.5)), 3)
        elif risk_level < 0.35:
            # Low-risk: generally solid with some gaps
            score = round(float(np.random.beta(4.0, 2.0)), 3)
        else:
            # Medium-risk: normal distribution
            score = round(float(np.clip(np.random.normal(0.6, 0.2), 0.0, 1.0)), 3)
        ikp[skill] = score
    return ikp


def _generate_engagement_metrics(risk_level: float, days: int = 30) -> dict:
    """
    Simulate 30-day engagement metrics.
    High-risk students show declining streaks, fewer leaderboard checks, etc.
    """
    if risk_level > 0.65:
        streak = random.randint(0, 5)
        leaderboard_checks = random.randint(0, 8)
        challenge_refusals = random.randint(4, 15)
        daily_xp = [max(0, int(np.random.normal(20, 30))) for _ in range(days)]
        sessions_per_week = round(random.uniform(0.5, 2.5), 1)
    elif risk_level < 0.35:
        streak = random.randint(10, 60)
        leaderboard_checks = random.randint(15, 50)
        challenge_refusals = random.randint(0, 3)
        daily_xp = [max(0, int(np.random.normal(150, 40))) for _ in range(days)]
        sessions_per_week = round(random.uniform(5.0, 7.0), 1)
    else:
        streak = random.randint(3, 20)
        leaderboard_checks = random.randint(5, 25)
        challenge_refusals = random.randint(1, 8)
        daily_xp = [max(0, int(np.random.normal(75, 35))) for _ in range(days)]
        sessions_per_week = round(random.uniform(2.5, 5.0), 1)

    streak_delta = streak - random.randint(0, max(0, streak - 1))  # streak drop
    xp_trend = float(np.polyfit(range(days), daily_xp, 1)[0])  # slope

    return {
        "current_streak": streak,
        "streak_delta_7d": streak_delta,
        "total_xp": sum(daily_xp),
        "daily_xp": daily_xp,
        "xp_trend_slope": round(xp_trend, 4),
        "leaderboard_checks_30d": leaderboard_checks,
        "challenge_refusals_30d": challenge_refusals,
        "sessions_per_week": sessions_per_week,
        "avg_session_minutes": round(random.uniform(5, 90) if risk_level > 0.65 else random.uniform(20, 120), 1),
    }


def _generate_interaction_logs(student_id: int, ikp: dict) -> list:
    """
    Generate per-module interaction records: score, attempts, time_minutes.
    Modules with higher proficiency get better scores.
    """
    logs = []
    for i, skill in enumerate(SKILL_NODES):
        proficiency = ikp[skill]
        if proficiency < 0.2:
            # Likely hasn't attempted or failed
            continue
        attempts = random.randint(1, 5) if proficiency < 0.5 else 1
        score = round(float(np.clip(np.random.normal(proficiency, 0.1), 0.0, 1.0)), 3)
        time_minutes = round(random.uniform(10, 120) * (1.5 - proficiency), 1)
        completed = proficiency >= 0.5
        logs.append({
            "student_id": student_id,
            "module_index": i,
            "module_name": skill,
            "score": score,
            "attempts": attempts,
            "time_minutes": time_minutes,
            "completed": completed,
            "timestamp": (datetime.now() - timedelta(days=random.randint(0, 90))).isoformat(),
        })
    return logs


def generate_students() -> list[dict]:
    """
    Generate N_STUDENTS synthetic student records.

    Returns:
        List of dicts, each representing one student's full profile.
    """
    students = []
    for i in range(N_STUDENTS):
        student_id = f"STU-{1000 + i}"
        # Assign dropout risk: ~25% high, ~25% low, 50% medium
        roll = random.random()
        if roll < 0.25:
            risk_level = round(random.uniform(0.65, 0.99), 3)
            dropout_label = 1
        elif roll < 0.50:
            risk_level = round(random.uniform(0.0, 0.35), 3)
            dropout_label = 0
        else:
            risk_level = round(random.uniform(0.35, 0.65), 3)
            dropout_label = 1 if random.random() > 0.7 else 0

        ikp = _generate_ikp(risk_level)
        engagement = _generate_engagement_metrics(risk_level)
        interactions = _generate_interaction_logs(i, ikp)

        students.append({
            "student_id": student_id,
            "risk_level": risk_level,
            "dropout_label": dropout_label,
            "ikp": ikp,
            "engagement": engagement,
            "interactions": interactions,
            "signup_date": (datetime.now() - timedelta(days=random.randint(30, 365))).isoformat(),
            "cohort": f"cohort_{random.choice(['A', 'B', 'C', 'D'])}",
        })
    return students


def generate_interaction_matrix() -> np.ndarray:
    """
    Build an (N_STUDENTS, N_MODULES) interaction matrix of raw scores.
    Missing values (not attempted) are represented as 0.0.

    Returns:
        numpy array of shape (200, 32)
    """
    students = generate_students()
    matrix = np.zeros((N_STUDENTS, N_MODULES))
    for idx, student in enumerate(students):
        for log in student["interactions"]:
            module_idx = log["module_index"]
            matrix[idx, module_idx] = log["score"]
    return matrix


if __name__ == "__main__":
    students = generate_students()
    print(f"Generated {len(students)} student profiles")
    print(f"Sample student: {json.dumps(students[0], indent=2, default=str)}")

    matrix = generate_interaction_matrix()
    print(f"\nInteraction matrix shape: {matrix.shape}")
    print(f"Matrix sparsity: {(matrix == 0).sum() / matrix.size:.1%}")

"""
matrix_factory.py
-----------------
Constructs the student × module interaction matrix used by the collaborative
filtering layer. In production, this matrix would be read from PostgreSQL;
in this implementation it is built from the mock student data.

Each cell (i, j) represents a composite interaction score between
student i and module j, combining:
  - Normalised raw score
  - Completion status bonus
  - Attempt efficiency (fewer attempts → higher score)
  - Time-efficiency (faster relative to module average → slight boost)

Usage:
    from ML.recommendation.matrix_factory import build_interaction_matrix

    matrix, student_ids, module_ids = build_interaction_matrix()
    # matrix.shape == (200, 32)
"""

from __future__ import annotations

import numpy as np
import sys
from pathlib import Path

# Allow importing from sibling ML packages
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from ML.data.mock_students import generate_students, SKILL_NODES

# Weights for composite interaction score
W_SCORE = 0.55
W_COMPLETION = 0.25
W_ATTEMPTS = 0.12
W_TIME = 0.08

# If fewer than this many students have interacted with a module, fill with 0
MIN_INTERACTIONS_PER_MODULE = 3


def _compute_cell_score(
    score: float,
    completed: bool,
    attempts: int,
    time_minutes: float,
    module_avg_time: float,
) -> float:
    """
    Compute the composite interaction score for a single (student, module) pair.

    Args:
        score:            Raw assessment score [0.0, 1.0]
        completed:        Whether the student completed the module
        attempts:         Number of attempts taken
        time_minutes:     Time the student spent (minutes)
        module_avg_time:  Average time spent on this module across all students

    Returns:
        Composite interaction score in [0.0, 1.0]
    """
    # Score component
    score_component = score * W_SCORE

    # Completion bonus
    completion_component = (1.0 if completed else 0.5) * W_COMPLETION

    # Attempt efficiency: max 1 attempt = 1.0, 5+ attempts = 0.0
    attempt_efficiency = max(0.0, 1.0 - (attempts - 1) / 4.0)
    attempts_component = attempt_efficiency * W_ATTEMPTS

    # Time efficiency: spending significantly less time than average = slight bonus
    if module_avg_time > 0:
        time_ratio = time_minutes / module_avg_time
        # Faster is slightly better; cap benefit/penalty
        time_efficiency = np.clip(1.5 - time_ratio, 0.0, 1.0)
    else:
        time_efficiency = 0.5
    time_component = time_efficiency * W_TIME

    return float(score_component + completion_component + attempts_component + time_component)


def build_interaction_matrix(
    students: list[dict] | None = None,
) -> tuple[np.ndarray, list[str], list[str]]:
    """
    Build the (N_students × N_modules) composite interaction matrix.

    Args:
        students: Optional pre-generated student list. If None, generates fresh.

    Returns:
        Tuple of:
          - matrix: np.ndarray of shape (N_students, N_modules), dtype float32
          - student_ids: list of student ID strings (row labels)
          - module_ids: list of module/skill IDs (column labels)
    """
    if students is None:
        students = generate_students()

    n_students = len(students)
    n_modules = len(SKILL_NODES)
    module_index = {skill: i for i, skill in enumerate(SKILL_NODES)}

    # First pass: collect all times per module to compute averages
    module_times: list[list[float]] = [[] for _ in range(n_modules)]
    for student in students:
        for log in student["interactions"]:
            m_idx = module_index.get(log["module_name"])
            if m_idx is not None:
                module_times[m_idx].append(log["time_minutes"])

    module_avg_times = [
        float(np.mean(times)) if times else 30.0 for times in module_times
    ]

    # Second pass: fill the matrix
    matrix = np.zeros((n_students, n_modules), dtype=np.float32)
    student_ids: list[str] = []

    for row_idx, student in enumerate(students):
        student_ids.append(student["student_id"])
        for log in student["interactions"]:
            m_idx = module_index.get(log["module_name"])
            if m_idx is None:
                continue
            cell = _compute_cell_score(
                score=log["score"],
                completed=log["completed"],
                attempts=log["attempts"],
                time_minutes=log["time_minutes"],
                module_avg_time=module_avg_times[m_idx],
            )
            matrix[row_idx, m_idx] = cell

    return matrix, student_ids, list(SKILL_NODES)


if __name__ == "__main__":
    matrix, student_ids, module_ids = build_interaction_matrix()
    print(f"Matrix shape:    {matrix.shape}")
    print(f"Sparsity:        {(matrix == 0).sum() / matrix.size:.1%}")
    print(f"Mean (non-zero): {matrix[matrix > 0].mean():.4f}")
    print(f"Student sample:  {student_ids[:5]}")
    print(f"Module sample:   {module_ids[:5]}")

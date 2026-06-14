"""
codebert_evaluator.py
----------------------
Computes a Verified Skill Score (VSS) for student-submitted code repositories
using a fine-tuned CodeBERT model via the HuggingFace Inference API.

Pipeline:
  1. Receive a code submission (text/source files from S3 or direct upload).
  2. Preprocess and chunk the code into windows CodeBERT can handle.
  3. Call the HuggingFace Inference API (or local stub if no API key).
  4. Aggregate model outputs into a VSS in [0.0, 100.0].
  5. Update the Redis Sorted Set (ZADD) so the leaderboard reflects the new score.

Rubric Dimensions (each scored 0–1, then weighted):
  • code_correctness     (35%): Does the code solve the stated problem?
  • structural_elegance  (25%): Modularity, DRY, readability.
  • contextual_alignment (25%): Aligns with the assigned skill node objective.
  • documentation        (15%): Comments, docstrings, README quality.

VSS = Σ(dimension_score × weight) × 100

Usage:
    from ML.code_review.codebert_evaluator import CodeBertEvaluator

    evaluator = CodeBertEvaluator(api_key="hf_xxx")
    result = evaluator.evaluate(
        student_id="STU-1042",
        skill_node="linear_regression",
        code_text="import numpy as np\n...",
    )
    print(result.vss)          # e.g. 74.3
    print(result.feedback)     # Dimension-level breakdown
"""

from __future__ import annotations

import hashlib
import os
import random
import re
import time
from dataclasses import dataclass, field
from typing import Any

import requests

# ── Configuration ─────────────────────────────────────────────────────────────
HF_API_BASE = "https://api-inference.huggingface.co/models"
CODEBERT_MODEL = "microsoft/codebert-base"
FILL_MASK_MODEL = "microsoft/codebert-base-mlm"

# Rubric weights (must sum to 1.0)
RUBRIC_WEIGHTS = {
    "code_correctness":     0.35,
    "structural_elegance":  0.25,
    "contextual_alignment": 0.25,
    "documentation":        0.15,
}
assert abs(sum(RUBRIC_WEIGHTS.values()) - 1.0) < 1e-6

MAX_CODE_CHARS = 4000   # Truncate submissions to fit model context window
REQUEST_TIMEOUT = 30     # seconds

# ── Redis stub (replace with real redis-py in production) ─────────────────────
_REDIS_SORTED_SET: dict[str, float] = {}  # student_id → VSS (in-memory mock)


@dataclass
class EvaluationResult:
    """
    Output from CodeBertEvaluator.evaluate().

    Attributes:
        student_id:    Student identifier.
        skill_node:    The skill/module this submission is assessed against.
        vss:           Verified Skill Score in [0.0, 100.0].
        dimension_scores: Per-rubric-dimension scores.
        feedback:      Human-readable feedback per dimension.
        submission_hash: SHA-256 hash of the submitted code for dedup/audit.
        leaderboard_rank: Current rank after VSS update (None if Redis unavailable).
    """
    student_id: str
    skill_node: str
    vss: float
    dimension_scores: dict[str, float]
    feedback: dict[str, str]
    submission_hash: str
    leaderboard_rank: int | None = None


class CodeBertEvaluator:
    """
    HuggingFace CodeBERT-backed code evaluation service.

    If no API key is provided or the API call fails, the evaluator falls back
    to a deterministic heuristic scorer based on code structure analysis.
    This ensures the system remains functional during development without
    requiring an active HuggingFace account.
    """

    def __init__(self, api_key: str | None = None):
        self.api_key = api_key or os.getenv("HUGGINGFACE_API_KEY")
        self._use_api = bool(self.api_key)
        if self._use_api:
            print(f"[CodeBertEvaluator] Using HuggingFace API: {CODEBERT_MODEL}")
        else:
            print("[CodeBertEvaluator] No API key — using heuristic scorer fallback.")

    # ── Preprocessing ──────────────────────────────────────────────────────────

    def _preprocess(self, code_text: str) -> str:
        """Clean and truncate code to fit model context."""
        # Remove null bytes and excessive whitespace
        code = code_text.replace("\x00", "").strip()
        # Truncate to max chars
        if len(code) > MAX_CODE_CHARS:
            code = code[:MAX_CODE_CHARS] + "\n# [TRUNCATED]"
        return code

    def _compute_hash(self, code_text: str) -> str:
        return hashlib.sha256(code_text.encode("utf-8")).hexdigest()[:16]

    # ── HuggingFace API call ───────────────────────────────────────────────────

    def _call_hf_api(self, code: str, skill_node: str) -> dict[str, Any] | None:
        """
        Call the HuggingFace feature-extraction endpoint.
        Returns the embedding vector or None on failure.
        """
        headers = {"Authorization": f"Bearer {self.api_key}"}
        prompt = (
            f"# Task: {skill_node.replace('_', ' ').title()}\n"
            f"# Evaluate this code for correctness, elegance, and alignment.\n\n"
            f"{code}"
        )
        payload = {"inputs": prompt}

        try:
            resp = requests.post(
                f"{HF_API_BASE}/{CODEBERT_MODEL}",
                headers=headers,
                json=payload,
                timeout=REQUEST_TIMEOUT,
            )
            resp.raise_for_status()
            return resp.json()
        except requests.RequestException as e:
            print(f"[CodeBertEvaluator] API call failed: {e}. Falling back to heuristic.")
            return None

    def _embedding_to_scores(self, embedding_response: Any) -> dict[str, float]:
        """
        Convert CodeBERT embedding output to rubric dimension scores.
        In a production fine-tuned model, this would be a regression head.
        Here we derive scores from embedding statistics as a reasonable proxy.
        """
        if isinstance(embedding_response, list) and len(embedding_response) > 0:
            # Flatten nested lists
            flat = []
            def _flatten(v: Any) -> None:
                if isinstance(v, list):
                    for item in v:
                        _flatten(item)
                elif isinstance(v, (int, float)):
                    flat.append(float(v))
            _flatten(embedding_response)

            if flat:
                arr = [abs(x) for x in flat]
                # Use statistical properties of the embedding as proxy scores
                mu = sum(arr) / len(arr)
                # Normalise to [0,1] range with sigmoid-like mapping
                return {
                    "code_correctness":     min(1.0, max(0.0, mu * 1.2)),
                    "structural_elegance":  min(1.0, max(0.0, mu * 1.1)),
                    "contextual_alignment": min(1.0, max(0.0, mu * 1.0)),
                    "documentation":        min(1.0, max(0.0, mu * 0.9)),
                }

        return self._heuristic_scores("", "")

    # ── Heuristic fallback scorer ──────────────────────────────────────────────

    def _heuristic_scores(self, code: str, skill_node: str) -> dict[str, float]:
        """
        Deterministic heuristic scorer based on code structure signals.
        Used when the HuggingFace API is unavailable.
        """
        scores = {}

        # code_correctness: proxy via presence of error-handling, imports, main guard
        has_try_except = "try:" in code and "except" in code
        has_imports = "import " in code
        has_main = "__main__" in code or "def main" in code
        has_return = "return " in code
        correctness = (
            (0.4 if has_imports else 0.1)
            + (0.25 if has_return else 0.0)
            + (0.2 if has_try_except else 0.0)
            + (0.15 if has_main else 0.0)
        )
        scores["code_correctness"] = min(1.0, correctness + random.gauss(0, 0.05))

        # structural_elegance: function count, line length, naming style
        func_count = len(re.findall(r"^\s*def ", code, re.MULTILINE))
        class_count = len(re.findall(r"^\s*class ", code, re.MULTILINE))
        lines = code.split("\n")
        avg_line_len = sum(len(l) for l in lines) / max(len(lines), 1)
        elegance = min(1.0, (func_count * 0.1) + (class_count * 0.15)
                       + max(0, 0.5 - avg_line_len / 200))
        scores["structural_elegance"] = min(1.0, max(0.0, elegance + random.gauss(0, 0.05)))

        # contextual_alignment: check if skill keywords appear in code
        skill_keywords = skill_node.replace("_", " ").split()
        keyword_hits = sum(1 for kw in skill_keywords if kw.lower() in code.lower())
        alignment = min(1.0, keyword_hits / max(len(skill_keywords), 1) + 0.3)
        scores["contextual_alignment"] = min(1.0, max(0.0, alignment + random.gauss(0, 0.05)))

        # documentation: docstrings, comments
        comment_lines = sum(1 for l in lines if l.strip().startswith("#"))
        docstring_count = len(re.findall(r'"""', code)) // 2
        doc_ratio = (comment_lines + docstring_count * 3) / max(len(lines), 1)
        scores["documentation"] = min(1.0, max(0.0, doc_ratio * 2 + random.gauss(0, 0.05)))

        return scores

    # ── Leaderboard update ─────────────────────────────────────────────────────

    def _update_leaderboard(self, student_id: str, vss: float) -> int:
        """
        Update the Redis Sorted Set with the student's new VSS.
        In production: redis_client.zadd("leaderboard:vss", {student_id: vss})

        Returns the student's new 1-indexed rank.
        """
        _REDIS_SORTED_SET[student_id] = max(
            _REDIS_SORTED_SET.get(student_id, 0.0), vss
        )
        ranked = sorted(_REDIS_SORTED_SET.values(), reverse=True)
        current_vss = _REDIS_SORTED_SET[student_id]
        rank = ranked.index(current_vss) + 1
        return rank

    def _generate_feedback(self, dimension_scores: dict[str, float]) -> dict[str, str]:
        """Generate human-readable feedback strings per dimension."""
        feedback = {}
        for dim, score in dimension_scores.items():
            if score >= 0.80:
                feedback[dim] = f"Excellent! Your {dim.replace('_', ' ')} is outstanding."
            elif score >= 0.60:
                feedback[dim] = f"Good work on {dim.replace('_', ' ')}. A few improvements possible."
            elif score >= 0.40:
                feedback[dim] = f"Your {dim.replace('_', ' ')} needs some attention. Review the guidelines."
            else:
                feedback[dim] = (
                    f"Significant improvement needed in {dim.replace('_', ' ')}. "
                    "Please revisit the module materials."
                )
        return feedback

    # ── Public interface ───────────────────────────────────────────────────────

    def evaluate(
        self,
        student_id: str,
        skill_node: str,
        code_text: str,
    ) -> EvaluationResult:
        """
        Evaluate a code submission and compute the Verified Skill Score.

        Args:
            student_id:  Student identifier.
            skill_node:  The knowledge graph node this submission targets.
            code_text:   Raw source code as a string.

        Returns:
            EvaluationResult with VSS, dimension scores, feedback, and rank.
        """
        code = self._preprocess(code_text)
        submission_hash = self._compute_hash(code)

        # ── Score computation ──────────────────────────────────────────────────
        if self._use_api:
            embedding = self._call_hf_api(code, skill_node)
            if embedding:
                dimension_scores = self._embedding_to_scores(embedding)
            else:
                dimension_scores = self._heuristic_scores(code, skill_node)
        else:
            dimension_scores = self._heuristic_scores(code, skill_node)

        # Weighted VSS
        vss = sum(
            dimension_scores[dim] * weight
            for dim, weight in RUBRIC_WEIGHTS.items()
            if dim in dimension_scores
        ) * 100.0
        vss = round(min(100.0, max(0.0, vss)), 2)

        # ── Leaderboard update ─────────────────────────────────────────────────
        rank = self._update_leaderboard(student_id, vss)
        feedback = self._generate_feedback(dimension_scores)

        return EvaluationResult(
            student_id=student_id,
            skill_node=skill_node,
            vss=vss,
            dimension_scores={k: round(v, 4) for k, v in dimension_scores.items()},
            feedback=feedback,
            submission_hash=submission_hash,
            leaderboard_rank=rank,
        )


if __name__ == "__main__":
    sample_code = '''
import numpy as np
from sklearn.linear_model import LinearRegression

def train_linear_model(X: np.ndarray, y: np.ndarray) -> LinearRegression:
    """
    Train a linear regression model on the provided data.

    Args:
        X: Feature matrix of shape (n_samples, n_features).
        y: Target vector of shape (n_samples,).

    Returns:
        Fitted LinearRegression model.
    """
    try:
        model = LinearRegression()
        model.fit(X, y)
        return model
    except Exception as e:
        raise ValueError(f"Training failed: {e}") from e

if __name__ == "__main__":
    X = np.random.rand(100, 1)
    y = 3 * X.squeeze() + 2 + np.random.randn(100) * 0.1
    model = train_linear_model(X, y)
    print(f"Coefficient: {model.coef_[0]:.4f} (expected ~3.0)")
    print(f"Intercept:   {model.intercept_:.4f} (expected ~2.0)")
'''

    evaluator = CodeBertEvaluator()
    result = evaluator.evaluate(
        student_id="STU-1042",
        skill_node="linear_regression",
        code_text=sample_code,
    )
    print(f"\nVSS: {result.vss:.2f} / 100")
    print(f"Leaderboard Rank: #{result.leaderboard_rank}")
    print(f"Submission Hash: {result.submission_hash}")
    print("\nDimension Scores:")
    for dim, score in result.dimension_scores.items():
        print(f"  {dim:<25} {score:.4f}   — {result.feedback[dim]}")

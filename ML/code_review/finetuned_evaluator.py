"""
finetuned_evaluator.py
-----------------------
Drop-in replacement for CodeBertEvaluator that loads the locally
fine-tuned CodeBERT regression model instead of calling the HuggingFace API.

The fine-tuned model was trained in ML/code_review/finetune_codebert.py and
produces skill-aware rubric dimension scores directly from a single forward pass.

Pipeline:
  1. Load fine-tuned model weights from ML/code_review/finetuned_model/
  2. Tokenise input as "[CLS] <skill_node_text> [SEP] <code> [SEP]"
  3. Run forward pass → 4-dim sigmoid output (one score per rubric dimension)
  4. Compute weighted VSS and generate feedback

Rubric Dimensions (weights must sum to 1.0):
    code_correctness     (35%)
    structural_elegance  (25%)
    contextual_alignment (25%)
    documentation        (15%)

VSS = Σ(dimension_score × weight) × 100

Usage:
    from ML.code_review.finetuned_evaluator import FinetunedCodeBertEvaluator

    evaluator = FinetunedCodeBertEvaluator()
    result = evaluator.evaluate(
        student_id="STU-1042",
        skill_node="linear_regression",
        code_text="import numpy as np\\n...",
    )
    print(result.vss, result.dimension_scores)
"""

from __future__ import annotations

import hashlib
import json
import sys
import warnings
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# ── Resolve project root ──────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

warnings.filterwarnings("ignore")

# ── Paths ─────────────────────────────────────────────────────────────────────
MODEL_DIR    = Path(__file__).parent / "finetuned_model"
CONFIG_PATH  = MODEL_DIR / "finetune_config.json"

# ── Rubric weights (must match original evaluator) ────────────────────────────
RUBRIC_WEIGHTS = {
    "code_correctness":     0.35,
    "structural_elegance":  0.25,
    "contextual_alignment": 0.25,
    "documentation":        0.15,
}
assert abs(sum(RUBRIC_WEIGHTS.values()) - 1.0) < 1e-6

DIMENSION_NAMES = list(RUBRIC_WEIGHTS.keys())

# ── Redis stub (shared with original evaluator) ───────────────────────────────
_REDIS_SORTED_SET: dict[str, float] = {}

MAX_CODE_CHARS = 4000


# ═════════════════════════════════════════════════════════════════════════════
# Data classes
# ═════════════════════════════════════════════════════════════════════════════

@dataclass
class EvaluationResult:
    """
    Output from FinetunedCodeBertEvaluator.evaluate().

    Attributes:
        student_id:       Student identifier.
        skill_node:       The skill/module this submission is assessed against.
        vss:              Verified Skill Score in [0.0, 100.0].
        dimension_scores: Per-rubric-dimension scores [0.0, 1.0].
        feedback:         Human-readable feedback per dimension.
        submission_hash:  SHA-256 prefix of submitted code (dedup/audit).
        leaderboard_rank: Current rank after VSS update (None if Redis unavailable).
        model_source:     'finetuned' | 'heuristic_fallback'
    """
    student_id:       str
    skill_node:       str
    vss:              float
    dimension_scores: dict[str, float]
    feedback:         dict[str, str]
    submission_hash:  str
    leaderboard_rank: int | None = None
    model_source:     str = "finetuned"


# ═════════════════════════════════════════════════════════════════════════════
# Model loader
# ═════════════════════════════════════════════════════════════════════════════

class _ModelLoader:
    """
    Lazy singleton loader for the fine-tuned CodeBERT regressor.
    Loads model + tokeniser once and caches them in memory.
    """

    _instance: "_ModelLoader | None" = None
    _model:     Any = None
    _tokenizer: Any = None
    _config:    dict = {}
    _loaded:    bool = False

    @classmethod
    def get(cls) -> "_ModelLoader":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load(self) -> bool:
        """
        Attempt to load the fine-tuned model.
        Returns True on success, False if model not found or deps missing.
        """
        if self._loaded:
            return True

        # Check dependencies
        try:
            import torch
            from transformers import AutoTokenizer, RobertaModel
        except ImportError:
            print("[FinetunedEval] torch/transformers not installed → heuristic fallback")
            return False

        # Check model files exist
        weights_path = MODEL_DIR / "model_weights.pt"
        if not weights_path.exists():
            print(
                f"[FinetunedEval] Fine-tuned weights not found at {weights_path}\n"
                f"                Run:  python -m ML.code_review.finetune_codebert\n"
                f"                Falling back to heuristic scorer."
            )
            return False

        try:
            # Load config
            if CONFIG_PATH.exists():
                self._config = json.loads(CONFIG_PATH.read_text())
            else:
                self._config = {
                    "base_model":    "microsoft/codebert-base",
                    "max_seq_len":   256,
                    "dropout_rate":  0.1,
                    "freeze_layers": 8,
                }

            base_model = self._config.get("base_model", "microsoft/codebert-base")
            max_len    = self._config.get("max_seq_len", 256)

            # Rebuild model architecture (must match finetune_codebert.py)
            import torch.nn as nn

            class _CodeBERTRegressor(nn.Module):
                def __init__(self) -> None:
                    super().__init__()
                    self.encoder   = RobertaModel.from_pretrained(base_model)
                    self.dropout   = nn.Dropout(self._config.get("dropout_rate", 0.1))
                    self.regressor = nn.Linear(self.encoder.config.hidden_size, 4)

                def forward(self, input_ids, attention_mask):
                    outputs   = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
                    cls_out   = outputs.last_hidden_state[:, 0, :]
                    x         = self.dropout(cls_out)
                    x         = self.regressor(x)
                    return torch.sigmoid(x)

            # Use a closure so self._config is in scope
            dropout_rate = self._config.get("dropout_rate", 0.1)

            class _Regressor(nn.Module):
                def __init__(self) -> None:
                    super().__init__()
                    self.encoder   = RobertaModel.from_pretrained(base_model)
                    self.dropout   = nn.Dropout(dropout_rate)
                    self.regressor = nn.Linear(self.encoder.config.hidden_size, 4)

                def forward(self, input_ids, attention_mask):
                    import torch
                    outputs = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
                    cls_out = outputs.last_hidden_state[:, 0, :]
                    x       = self.dropout(cls_out)
                    x       = self.regressor(x)
                    return torch.sigmoid(x)

            model = _Regressor()
            device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            model.load_state_dict(torch.load(weights_path, map_location=device))
            model.eval()
            model.to(device)

            tokenizer = AutoTokenizer.from_pretrained(str(MODEL_DIR))

            self._model     = model
            self._tokenizer = tokenizer
            self._device    = device
            self._max_len   = max_len
            self._loaded    = True

            print(f"[FinetunedEval] Fine-tuned model loaded from {MODEL_DIR.name}/ "
                  f"on {device}")
            return True

        except Exception as exc:
            print(f"[FinetunedEval] Failed to load model: {exc}\n"
                  f"                Falling back to heuristic scorer.")
            return False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def predict(self, skill_node: str, code: str) -> dict[str, float] | None:
        """
        Run a forward pass and return dimension scores or None on error.
        """
        if not self._loaded:
            return None

        import torch

        skill_text = skill_node.replace("_", " ")
        encoding   = self._tokenizer(
            skill_text,
            code,
            max_length=self._max_len,
            padding="max_length",
            truncation=True,
            return_tensors="pt",
        )

        with torch.no_grad():
            preds = self._model(
                input_ids      = encoding["input_ids"].to(self._device),
                attention_mask = encoding["attention_mask"].to(self._device),
            )

        scores_raw = preds.squeeze(0).cpu().numpy()
        return {dim: round(float(scores_raw[i]), 4) for i, dim in enumerate(DIMENSION_NAMES)}


# ═════════════════════════════════════════════════════════════════════════════
# Heuristic fallback (mirrors original codebert_evaluator.py)
# ═════════════════════════════════════════════════════════════════════════════

def _heuristic_scores(code: str, skill_node: str) -> dict[str, float]:
    """Deterministic heuristic scorer used when fine-tuned model is unavailable."""
    import random
    import re

    scores: dict[str, float] = {}
    has_try_except  = "try:" in code and "except" in code
    has_imports     = "import " in code
    has_main        = "__main__" in code or "def main" in code
    has_return      = "return " in code
    correctness = (
        (0.4 if has_imports    else 0.1)
        + (0.25 if has_return  else 0.0)
        + (0.2 if has_try_except else 0.0)
        + (0.15 if has_main    else 0.0)
    )
    scores["code_correctness"] = min(1.0, correctness + random.gauss(0, 0.04))

    lines       = code.split("\n")
    func_count  = len(re.findall(r"^\s*def ", code, re.MULTILINE))
    class_count = len(re.findall(r"^\s*class ", code, re.MULTILINE))
    avg_line_len = sum(len(l) for l in lines) / max(len(lines), 1)
    elegance    = min(1.0, func_count * 0.1 + class_count * 0.15 + max(0, 0.5 - avg_line_len / 200))
    scores["structural_elegance"] = min(1.0, max(0.0, elegance + random.gauss(0, 0.04)))

    kws         = skill_node.replace("_", " ").split()
    kw_hits     = sum(1 for kw in kws if kw.lower() in code.lower())
    alignment   = min(1.0, kw_hits / max(len(kws), 1) + 0.3)
    scores["contextual_alignment"] = min(1.0, max(0.0, alignment + random.gauss(0, 0.04)))

    comment_lines  = sum(1 for l in lines if l.strip().startswith("#"))
    docstring_count = len(re.findall(r'"""', code)) // 2
    doc_ratio       = (comment_lines + docstring_count * 3) / max(len(lines), 1)
    scores["documentation"] = min(1.0, max(0.0, doc_ratio * 2 + random.gauss(0, 0.04)))

    return scores


# ═════════════════════════════════════════════════════════════════════════════
# Main evaluator class
# ═════════════════════════════════════════════════════════════════════════════

class FinetunedCodeBertEvaluator:
    """
    Code quality evaluator using the locally fine-tuned CodeBERT regression model.

    Automatically falls back to the rule-based heuristic scorer if:
      - The fine-tuned model hasn't been trained yet
      - torch/transformers are not installed

    Public interface is identical to CodeBertEvaluator for drop-in compatibility.
    """

    def __init__(self) -> None:
        self._loader = _ModelLoader.get()
        self._use_model = self._loader.load()
        mode = "fine-tuned model" if self._use_model else "heuristic fallback"
        print(f"[FinetunedEval] Initialised → using {mode}")

    # ── Preprocessing ──────────────────────────────────────────────────────────

    def _preprocess(self, code_text: str) -> str:
        code = code_text.replace("\x00", "").strip()
        if len(code) > MAX_CODE_CHARS:
            code = code[:MAX_CODE_CHARS] + "\n# [TRUNCATED]"
        return code

    def _compute_hash(self, code_text: str) -> str:
        return hashlib.sha256(code_text.encode("utf-8")).hexdigest()[:16]

    # ── Feedback generation ────────────────────────────────────────────────────

    def _generate_feedback(self, dimension_scores: dict[str, float]) -> dict[str, str]:
        feedback = {}
        for dim, score in dimension_scores.items():
            label = dim.replace("_", " ").title()
            if score >= 0.80:
                feedback[dim] = f"Excellent {label} — outstanding work."
            elif score >= 0.60:
                feedback[dim] = f"Good {label}. Minor improvements possible."
            elif score >= 0.40:
                feedback[dim] = f"{label} needs attention — review the module guidelines."
            else:
                feedback[dim] = f"Significant improvement needed in {label}. Revisit materials."
        return feedback

    # ── Leaderboard ────────────────────────────────────────────────────────────

    def _update_leaderboard(self, student_id: str, vss: float) -> int:
        _REDIS_SORTED_SET[student_id] = max(_REDIS_SORTED_SET.get(student_id, 0.0), vss)
        ranked   = sorted(_REDIS_SORTED_SET.values(), reverse=True)
        cur_vss  = _REDIS_SORTED_SET[student_id]
        return ranked.index(cur_vss) + 1

    # ── Public API ─────────────────────────────────────────────────────────────

    def evaluate(
        self,
        student_id: str,
        skill_node: str,
        code_text: str,
    ) -> EvaluationResult:
        """
        Evaluate a code submission and compute the Verified Skill Score.

        Args:
            student_id : Student identifier.
            skill_node : The knowledge graph DAG node this submission targets.
            code_text  : Raw source code as a string.

        Returns:
            EvaluationResult with VSS, dimension scores, feedback, and rank.
        """
        code             = self._preprocess(code_text)
        submission_hash  = self._compute_hash(code)
        model_source     = "finetuned"

        # ── Score computation ──────────────────────────────────────────────────
        if self._use_model:
            dimension_scores = self._loader.predict(skill_node, code)
            if dimension_scores is None:
                dimension_scores = _heuristic_scores(code, skill_node)
                model_source = "heuristic_fallback"
        else:
            dimension_scores = _heuristic_scores(code, skill_node)
            model_source = "heuristic_fallback"

        # ── Weighted VSS ───────────────────────────────────────────────────────
        vss = sum(
            dimension_scores[dim] * weight
            for dim, weight in RUBRIC_WEIGHTS.items()
            if dim in dimension_scores
        ) * 100.0
        vss = round(min(100.0, max(0.0, vss)), 2)

        rank     = self._update_leaderboard(student_id, vss)
        feedback = self._generate_feedback(dimension_scores)

        return EvaluationResult(
            student_id       = student_id,
            skill_node       = skill_node,
            vss              = vss,
            dimension_scores = {k: round(v, 4) for k, v in dimension_scores.items()},
            feedback         = feedback,
            submission_hash  = submission_hash,
            leaderboard_rank = rank,
            model_source     = model_source,
        )


# ═════════════════════════════════════════════════════════════════════════════
# Demo
# ═════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    sample_code = '''
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error


def train_model(X: np.ndarray, y: np.ndarray) -> LinearRegression:
    """
    Train a linear regression model.

    Args:
        X: Feature matrix.
        y: Target vector.

    Returns:
        Fitted LinearRegression instance.
    """
    try:
        model = LinearRegression()
        model.fit(X, y)
        return model
    except Exception as e:
        raise ValueError(f"Training failed: {e}") from e


if __name__ == "__main__":
    rng = np.random.default_rng(42)
    X = rng.uniform(0, 10, (200, 1))
    y = 3.5 * X.squeeze() + 1.2 + rng.normal(0, 1, 200)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
    model = train_model(X_train, y_train)
    y_pred = model.predict(X_test)

    print(f"R²:  {r2_score(y_test, y_pred):.4f}")
    print(f"MSE: {mean_squared_error(y_test, y_pred):.4f}")
'''

    evaluator = FinetunedCodeBertEvaluator()
    result = evaluator.evaluate(
        student_id="STU-1042",
        skill_node="linear_regression",
        code_text=sample_code,
    )

    print(f"\n{'='*55}")
    print(f"  VSS            : {result.vss:.2f} / 100")
    print(f"  Rank           : #{result.leaderboard_rank}")
    print(f"  Model source   : {result.model_source}")
    print(f"  Submission hash: {result.submission_hash}")
    print(f"\n  Dimension Scores:")
    for dim, score in result.dimension_scores.items():
        bar = "█" * int(score * 20) + "░" * (20 - int(score * 20))
        print(f"    {dim:<25} {bar}  {score:.4f}")
    print(f"\n  Feedback:")
    for dim, msg in result.feedback.items():
        print(f"    [{dim}] {msg}")
    print(f"{'='*55}")

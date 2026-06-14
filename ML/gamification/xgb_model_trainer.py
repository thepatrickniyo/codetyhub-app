"""
xgb_model_trainer.py
---------------------
Trains an XGBoost binary classifier to predict student dropout risk.

Training flow:
  1. Generate 200 mock student profiles.
  2. Extract 34 behavioural features via feature_engineering.
  3. Split into train/validation (80/20 stratified).
  4. Train XGBoost with early stopping on validation AUC.
  5. Evaluate on holdout set and print a classification report.
  6. Save the trained model to ML/gamification/xgb_dropout_model.json

The saved model is then loaded by dropout_predictor.py for inference.

Usage:
    python -m ML.gamification.xgb_model_trainer
    # Produces: ML/gamification/xgb_dropout_model.json
"""

from __future__ import annotations

import sys
import json
from pathlib import Path

import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report,
    roc_auc_score,
    confusion_matrix,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from ML.data.mock_students import generate_students
from ML.gamification.feature_engineering import extract_feature_matrix, FEATURE_NAMES

MODEL_SAVE_PATH = Path(__file__).parent / "xgb_dropout_model.json"
FEATURE_META_PATH = Path(__file__).parent / "feature_meta.json"

# ── XGBoost import with graceful fallback ──────────────────────────────────────
try:
    import xgboost as xgb
    _XGB_AVAILABLE = True
except ImportError:
    _XGB_AVAILABLE = False
    print("[WARNING] xgboost not installed. Run: pip install xgboost")


def train(random_state: int = 42) -> None:
    """
    Train the XGBoost dropout predictor and save the model to disk.

    Args:
        random_state: Seed for reproducibility.
    """
    if not _XGB_AVAILABLE:
        raise ImportError("xgboost is required. Install with: pip install xgboost")

    print("Generating mock student data…")
    students = generate_students()

    print("Extracting 34 features…")
    X = extract_feature_matrix(students)
    y = np.array([s["dropout_label"] for s in students], dtype=np.int8)

    print(f"Dataset: {X.shape[0]} students, {X.shape[1]} features | "
          f"dropout rate: {y.mean():.1%}")

    # Stratified train/val split
    X_train, X_val, y_train, y_val = train_test_split(
        X, y,
        test_size=0.20,
        stratify=y,
        random_state=random_state,
    )

    # ── Model configuration ────────────────────────────────────────────────────
    scale_pos_weight = (y_train == 0).sum() / max((y_train == 1).sum(), 1)

    model = xgb.XGBClassifier(
        n_estimators=500,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.85,
        colsample_bytree=0.85,
        min_child_weight=3,
        scale_pos_weight=scale_pos_weight,
        objective="binary:logistic",
        eval_metric="auc",
        use_label_encoder=False,
        random_state=random_state,
        n_jobs=-1,
        early_stopping_rounds=40,
    )

    print("\nTraining XGBoost model…")
    model.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        verbose=50,
    )

    # ── Evaluation ────────────────────────────────────────────────────────────
    y_pred = model.predict(X_val)
    y_prob = model.predict_proba(X_val)[:, 1]

    print("\n=== Holdout Evaluation ===")
    print(f"ROC-AUC: {roc_auc_score(y_val, y_prob):.4f}")
    print("\nClassification Report:")
    print(classification_report(y_val, y_pred, target_names=["Retained", "Dropout"]))
    print("Confusion Matrix:")
    print(confusion_matrix(y_val, y_pred))

    # ── Feature Importance ────────────────────────────────────────────────────
    importances = model.feature_importances_
    top_idx = np.argsort(importances)[::-1][:10]
    print("\nTop 10 Feature Importances:")
    for rank, i in enumerate(top_idx, 1):
        print(f"  {rank:>2}. {FEATURE_NAMES[i]:<40} {importances[i]:.4f}")

    # ── Save model & feature metadata ─────────────────────────────────────────
    model.save_model(str(MODEL_SAVE_PATH))
    print(f"\nModel saved to: {MODEL_SAVE_PATH}")

    meta = {
        "feature_names": FEATURE_NAMES,
        "n_features": len(FEATURE_NAMES),
        "n_estimators": model.best_iteration,
        "roc_auc": round(roc_auc_score(y_val, y_prob), 4),
        "model_path": str(MODEL_SAVE_PATH),
        "risk_thresholds": {
            "low_risk_max": 0.35,
            "high_risk_min": 0.65,
        },
    }
    with open(FEATURE_META_PATH, "w") as f:
        json.dump(meta, f, indent=2)
    print(f"Feature metadata saved to: {FEATURE_META_PATH}")


if __name__ == "__main__":
    train()

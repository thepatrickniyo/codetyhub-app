# CodetyHub ML Infrastructure

Python ML microservice powering the CodetyHub Personalized Learning Platform.

## Architecture

```
ML/
├── data/                  # Mock data generator (200 student profiles)
├── knowledge_graph/       # NetworkX DAG — STEM curriculum + prerequisite engine
├── recommendation/        # SVD collaborative filtering
├── gamification/          # XGBoost dropout predictor + 34-feature engineering
├── code_review/           # CodeBERT VSS code evaluator
└── api/                   # FastAPI microservice
    ├── routes/
    │   ├── pathway_routes.py
    │   ├── gamification_routes.py
    │   └── code_review_routes.py
    ├── schemas.py
    └── main.py
```

## Quick Start

### 1. Install dependencies

```bash
cd ML
pip install -r requirements.txt
```

> `torch` and `transformers` are optional — the CodeBERT evaluator uses a
> heuristic fallback if no HuggingFace API key is set.

### 2. (Optional) Train the XGBoost dropout model

```bash
python -m ML.gamification.xgb_model_trainer
# Produces: ML/gamification/xgb_dropout_model.json
```

### 3. Start the FastAPI server

```bash
uvicorn ML.api.main:app --reload --port 8000
```

### 4. Explore the API docs

- Swagger UI: http://localhost:8000/docs
- ReDoc:      http://localhost:8000/redoc

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/pathway/recommend` | Hybrid adaptive pathway recommendation |
| GET  | `/pathway/graph/info` | Knowledge graph statistics |
| GET  | `/pathway/graph/prerequisites/{skill_id}` | Prerequisite lookup |
| POST | `/gamification/risk` | Single student dropout risk prediction |
| POST | `/gamification/batch` | Batch daily risk assessment |
| GET  | `/gamification/features` | 34 feature catalogue |
| POST | `/code-review/evaluate` | CodeBERT VSS code evaluation |
| GET  | `/code-review/leaderboard` | VSS talent leaderboard |
| GET  | `/code-review/rubric` | Evaluation rubric & weights |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HUGGINGFACE_API_KEY` | — | HuggingFace Inference API key for CodeBERT |

## Module Summary

### Knowledge Graph (`knowledge_graph/`)
- **32 STEM skill nodes** across 13 academic levels
- **36 directed prerequisite edges** forming a valid DAG
- `PathEngine` classifies skills per-student and computes hybrid priority scores

### Collaborative Filtering (`recommendation/`)
- TruncatedSVD with **N=20 latent components**
- Finds **N=20 most similar peer students** via cosine similarity
- Ranks candidate modules by **weighted peer success rate**

### Dropout Predictor (`gamification/`)
- **34 engineered features** across 6 categories
- XGBoost binary classifier with early stopping on AUC
- Risk bands: LOW (< 0.35), MEDIUM (0.35–0.65), HIGH (≥ 0.65)
- HIGH risk triggers: Streak Recovery Token, Bonus XP Challenge, Peer Study Room invite

### Code Review (`code_review/`)
- CodeBERT via HuggingFace Inference API (heuristic fallback available)
- VSS rubric: correctness (35%), elegance (25%), alignment (25%), docs (15%)
- Updates Redis Sorted Set (ZADD) for real-time leaderboard positioning

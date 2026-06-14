"""
ML/api/main.py
--------------
FastAPI application entry point for the CodetyHub ML Microservice.

Registered routers:
  /pathway      — Hybrid adaptive learning pathway recommendations
  /gamification — XGBoost dropout risk prediction & gamification engine
  /code-review  — CodeBERT Verified Skill Score evaluation

Run locally:
    uvicorn ML.api.main:app --reload --port 8000

Interactive docs:
    http://localhost:8000/docs     (Swagger UI)
    http://localhost:8000/redoc    (ReDoc)
"""

from __future__ import annotations

import sys
from contextlib import asynccontextmanager
from pathlib import Path
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Ensure ML package is importable regardless of working directory
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from ML.api.routes.pathway_routes import router as pathway_router, get_path_engine, get_collab_filter
from ML.api.routes.gamification_routes import router as gamification_router, get_predictor
from ML.api.routes.code_review_routes import router as code_review_router, get_evaluator
from ML.api.schemas import HealthResponse


# ── Lifespan: warm up singletons at startup ────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    Startup: initialise ML singletons so the first request isn't slow.
    Shutdown: clean up (nothing needed for now).
    """
    print("[startup] Loading knowledge graph…")
    get_path_engine()

    print("[startup] Fitting collaborative filter…")
    try:
        get_collab_filter()
    except Exception as e:
        print(f"[startup] Collaborative filter warning: {e}")

    print("[startup] Loading dropout predictor…")
    get_predictor()

    print("[startup] Initialising code evaluator…")
    get_evaluator()

    print("[startup] ✅ CodetyHub ML API is ready.")
    yield
    print("[shutdown] CodetyHub ML API shutting down.")


# ── App factory ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="CodetyHub ML API",
    description=(
        "Hybrid Adaptive Recommendation Engine, XGBoost Dropout Predictor, "
        "and CodeBERT Verified Skill Score microservice for the CodetyHub platform."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(pathway_router)
app.include_router(gamification_router)
app.include_router(code_review_router)


# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/", response_model=HealthResponse, tags=["Health"])
async def root() -> HealthResponse:
    """Service health check."""
    return HealthResponse()


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health() -> HealthResponse:
    """Detailed health check."""
    return HealthResponse()


# ── Dev entrypoint ────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("ML.api.main:app", host="0.0.0.0", port=8000, reload=True)

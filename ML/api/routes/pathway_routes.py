"""
pathway_routes.py
-----------------
FastAPI router for the Hybrid Adaptive Pathway Recommendation Engine.

Endpoints:
  POST /pathway/recommend   — Generate personalised module recommendations
  GET  /pathway/graph/info  — Return knowledge graph statistics
  GET  /pathway/graph/prerequisites/{skill_id}  — List prerequisites for a skill
"""

from __future__ import annotations

import sys
from pathlib import Path

from fastapi import APIRouter, HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from ML.api.schemas import (
    PathwayRecommendRequest,
    PathwayRecommendResponse,
    SkillRecommendation,
)
from ML.knowledge_graph.graph_builder import (
    describe_graph,
    get_prerequisites,
    load_graph,
)
from ML.knowledge_graph.path_engine import PathEngine
from ML.recommendation.collab_filter import CollaborativeFilter

router = APIRouter(prefix="/pathway", tags=["Pathway Recommendation"])

# Module-level singletons (loaded once at startup via lifespan)
_path_engine: PathEngine | None = None
_collab_filter: CollaborativeFilter | None = None


def get_path_engine() -> PathEngine:
    global _path_engine
    if _path_engine is None:
        _path_engine = PathEngine()
    return _path_engine


def get_collab_filter() -> CollaborativeFilter:
    global _collab_filter
    if _collab_filter is None:
        _collab_filter = CollaborativeFilter()
        _collab_filter.fit()
    return _collab_filter


@router.post("/recommend", response_model=PathwayRecommendResponse)
async def recommend_pathway(request: PathwayRecommendRequest) -> PathwayRecommendResponse:
    """
    Generate personalised learning pathway recommendations for a student.

    Combines:
    1. Rule-based path filtering (NetworkX DAG prerequisite traversal).
    2. Collaborative Filtering (SVD peer similarity), if `include_collaborative=True`.

    Returns ordered list of recommended skill IDs with hybrid confidence scores.
    """
    ikp = request.ikp.proficiency_scores
    engine = get_path_engine()

    # Step 1: Rule-based recommendations
    path_result = engine.recommend(ikp, top_n=request.top_n * 2)

    rule_scores: dict[str, float] = path_result.priority_scores
    collab_scores: dict[str, float] = {}

    # Step 2: Collaborative filtering overlay
    if request.include_collaborative:
        try:
            cf = get_collab_filter()
            mastered_set = set(path_result.mastered)
            collab_recs = cf.recommend_for_vector(ikp, top_n=request.top_n * 2, already_mastered=mastered_set)
            collab_scores = {skill: conf for skill, conf in collab_recs}
        except Exception as e:
            # Gracefully degrade to rule-based only
            print(f"[pathway_routes] Collaborative filter error: {e}")

    # Step 3: Hybrid scoring — merge rule-based + collaborative
    all_candidates = set(list(rule_scores.keys()) + list(collab_scores.keys()))
    graph = load_graph()

    recommendations: list[SkillRecommendation] = []
    for skill in all_candidates:
        r_score = rule_scores.get(skill, 0.0)
        c_score = collab_scores.get(skill, 0.0)
        hybrid = (0.5 * r_score) + (0.5 * c_score) if c_score else r_score
        node_data = graph.nodes.get(skill, {})
        recommendations.append(SkillRecommendation(
            skill_id=skill,
            label=node_data.get("label", skill),
            rule_based_priority=round(r_score, 4) if skill in rule_scores else None,
            collaborative_confidence=round(c_score, 4) if skill in collab_scores else None,
            hybrid_score=round(hybrid, 4),
        ))

    # Sort by hybrid score and take top_n
    recommendations.sort(key=lambda r: r.hybrid_score, reverse=True)
    top_recs = recommendations[: request.top_n]

    # Compute completion stats
    total_skills = graph.number_of_nodes()
    mastered_count = len(path_result.mastered)
    completion_pct = round((mastered_count / total_skills) * 100, 1) if total_skills > 0 else 0.0

    return PathwayRecommendResponse(
        student_id=request.student_id,
        mastered=path_result.mastered,
        in_progress=path_result.in_progress,
        recommendations=top_recs,
        total_skills=total_skills,
        completion_pct=completion_pct,
    )


@router.get("/graph/info")
async def graph_info() -> dict:
    """Return high-level statistics about the STEM knowledge graph."""
    return describe_graph()


@router.get("/graph/prerequisites/{skill_id}")
async def skill_prerequisites(skill_id: str) -> dict:
    """List direct and transitive prerequisites for a given skill node."""
    try:
        direct = get_prerequisites(skill_id)
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Skill '{skill_id}' not found in graph.")

    import networkx as nx
    G = load_graph()
    transitive = list(nx.ancestors(G, skill_id))

    return {
        "skill_id": skill_id,
        "direct_prerequisites": direct,
        "all_prerequisites": transitive,
        "depth": len(transitive),
    }

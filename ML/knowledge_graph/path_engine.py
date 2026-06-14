"""
path_engine.py
--------------
The Rule-Based Filtering layer of the CodetyHub Hybrid Adaptive Recommendation
Engine.

Given a student's Individual Knowledge Profile (IKP — a dict mapping skill IDs
to proficiency scores in [0.0, 1.0]), this engine traverses the prerequisite
DAG to determine:
  1. Which skills the student has already mastered (proficiency ≥ threshold).
  2. Which skills are currently unlocked (all prerequisites mastered).
  3. Which skills are recommended next (ordered by strategic priority).

This output is then passed to the Collaborative Filtering layer
(ML/recommendation/collab_filter.py) for personalised re-ranking.

Usage:
    from ML.knowledge_graph.path_engine import PathEngine

    engine = PathEngine()
    result = engine.recommend(ikp, top_n=5)
    print(result.unlocked)       # List of available skill IDs
    print(result.recommended)    # Ordered recommendation list
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

import networkx as nx

from .graph_builder import load_graph

# Proficiency score at or above this value means a skill is "mastered"
MASTERY_THRESHOLD = 0.65

# Skills below this score are "not started" (no meaningful progress)
ATTEMPTED_THRESHOLD = 0.20


@dataclass
class PathResult:
    """
    Output from PathEngine.recommend().

    Attributes:
        mastered:       Skills the student has mastered (proficiency ≥ MASTERY_THRESHOLD).
        in_progress:    Skills started but not yet mastered.
        locked:         Skills whose prerequisites are not yet satisfied.
        unlocked:       Skills whose prerequisites are all mastered (ready to begin).
        recommended:    Ordered list of recommended next skills (rule-based priority).
        priority_scores: Map of skill_id → priority score for explanation/logging.
    """
    mastered: list[str] = field(default_factory=list)
    in_progress: list[str] = field(default_factory=list)
    locked: list[str] = field(default_factory=list)
    unlocked: list[str] = field(default_factory=list)
    recommended: list[str] = field(default_factory=list)
    priority_scores: dict[str, float] = field(default_factory=dict)


class PathEngine:
    """
    Rule-based path recommendation engine using the knowledge graph DAG.

    The engine classifies every skill into one of four states for a given
    student's IKP, then orders the unlocked-but-unmastered skills by a
    composite priority score:

        priority(s) = w1 * depth_factor(s)
                    + w2 * gap_penalty(s)
                    + w3 * prerequisite_coverage(s)

    where:
        depth_factor  = normalised topological depth (prefer shallower skills first)
        gap_penalty   = how far the student is from mastery on this skill
        prerequisite_coverage = fraction of ALL ancestors that are mastered
    """

    def __init__(
        self,
        mastery_threshold: float = MASTERY_THRESHOLD,
        attempted_threshold: float = ATTEMPTED_THRESHOLD,
        w_depth: float = 0.3,
        w_gap: float = 0.4,
        w_coverage: float = 0.3,
    ):
        self.G: nx.DiGraph = load_graph()
        self.mastery_threshold = mastery_threshold
        self.attempted_threshold = attempted_threshold
        self.w_depth = w_depth
        self.w_gap = w_gap
        self.w_coverage = w_coverage

        # Pre-compute topological depths for all nodes
        self._topo_depths: dict[str, int] = self._compute_depths()
        self._max_depth = max(self._topo_depths.values()) or 1

    def _compute_depths(self) -> dict[str, int]:
        """Compute the shortest path length from any root to every node."""
        roots = [n for n in self.G if self.G.in_degree(n) == 0]
        depths: dict[str, int] = {}
        for root in roots:
            lengths = nx.single_source_shortest_path_length(self.G, root)
            for node, length in lengths.items():
                depths[node] = min(depths.get(node, 99999), length)
        return depths

    def _is_mastered(self, skill: str, ikp: dict[str, float]) -> bool:
        return ikp.get(skill, 0.0) >= self.mastery_threshold

    def _all_prerequisites_mastered(self, skill: str, ikp: dict[str, float]) -> bool:
        return all(self._is_mastered(prereq, ikp) for prereq in self.G.predecessors(skill))

    def _ancestor_coverage(self, skill: str, ikp: dict[str, float]) -> float:
        """Fraction of ALL ancestors that the student has mastered."""
        ancestors = nx.ancestors(self.G, skill)
        if not ancestors:
            return 1.0
        mastered_count = sum(1 for a in ancestors if self._is_mastered(a, ikp))
        return mastered_count / len(ancestors)

    def _priority_score(self, skill: str, ikp: dict[str, float]) -> float:
        """
        Compute a composite priority score for an unlocked skill.
        Higher score = should be recommended first.
        """
        depth = self._topo_depths.get(skill, 0)
        depth_factor = 1.0 - (depth / self._max_depth)  # prefer shallower

        current_proficiency = ikp.get(skill, 0.0)
        gap_penalty = 1.0 - current_proficiency  # prefer skills student is closer to mastering

        coverage = self._ancestor_coverage(skill, ikp)

        return (
            self.w_depth * depth_factor
            + self.w_gap * gap_penalty
            + self.w_coverage * coverage
        )

    def classify(self, ikp: dict[str, float]) -> dict[str, list[str]]:
        """
        Classify all skills for a student.

        Args:
            ikp: Individual Knowledge Profile mapping skill_id → proficiency [0,1].

        Returns:
            Dict with keys 'mastered', 'in_progress', 'unlocked', 'locked'.
        """
        mastered, in_progress, unlocked, locked = [], [], [], []

        for skill in self.G.nodes():
            proficiency = ikp.get(skill, 0.0)
            if self._is_mastered(skill, ikp):
                mastered.append(skill)
            elif self._all_prerequisites_mastered(skill, ikp):
                if proficiency >= self.attempted_threshold:
                    in_progress.append(skill)
                else:
                    unlocked.append(skill)
            else:
                locked.append(skill)

        return {
            "mastered": mastered,
            "in_progress": in_progress,
            "unlocked": unlocked,
            "locked": locked,
        }

    def recommend(
        self,
        ikp: dict[str, float],
        top_n: int = 5,
        include_in_progress: bool = True,
    ) -> PathResult:
        """
        Generate an ordered list of recommended next skills for a student.

        Args:
            ikp:               Student's IKP (skill_id → proficiency score).
            top_n:             Maximum number of recommendations to return.
            include_in_progress: If True, in-progress skills are prioritised first.

        Returns:
            PathResult containing full classification and ordered recommendations.
        """
        classification = self.classify(ikp)

        candidates = []
        if include_in_progress:
            candidates.extend(classification["in_progress"])
        candidates.extend(classification["unlocked"])

        # Score each candidate
        priority_scores = {skill: self._priority_score(skill, ikp) for skill in candidates}

        # Sort descending by priority
        ordered = sorted(candidates, key=lambda s: priority_scores[s], reverse=True)

        return PathResult(
            mastered=classification["mastered"],
            in_progress=classification["in_progress"],
            locked=classification["locked"],
            unlocked=classification["unlocked"],
            recommended=ordered[:top_n],
            priority_scores=priority_scores,
        )


if __name__ == "__main__":
    # Demo: a student who has completed the Python fundamentals track
    sample_ikp = {
        "python_basics":        0.92,
        "data_types":           0.85,
        "control_flow":         0.80,
        "functions_scope":      0.75,
        "oop_fundamentals":     0.40,  # in progress
        "numpy_basics":         0.70,
        "statistics_fundamentals": 0.20,  # just unlocked
        "linear_algebra_basics":   0.0,   # unlocked but not started
    }

    engine = PathEngine()
    result = engine.recommend(sample_ikp, top_n=5)

    print(f"Mastered:     {result.mastered}")
    print(f"In Progress:  {result.in_progress}")
    print(f"Unlocked:     {result.unlocked}")
    print(f"Recommended:  {result.recommended}")
    print(f"\nPriority Scores:")
    for skill, score in sorted(result.priority_scores.items(), key=lambda x: -x[1]):
        print(f"  {skill:<30} {score:.4f}")

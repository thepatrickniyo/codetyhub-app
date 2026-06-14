"""
collab_filter.py
----------------
Collaborative Filtering layer of the CodetyHub Hybrid Adaptive Recommendation
Engine using Matrix Factorisation (Truncated SVD from scikit-learn).

Pipeline:
  1. Build the student × module interaction matrix (via matrix_factory).
  2. Decompose with TruncatedSVD to get latent factor representations.
  3. For a query student, find the N=20 most similar students in latent space
     using cosine similarity.
  4. Among those peers, identify modules they succeeded at that the query
     student has NOT yet completed.
  5. Rank those candidate modules by weighted peer success rate.

The output is a ranked list of module IDs that is then merged with the
rule-based path engine output (PathEngine.recommend()) to produce the final
hybrid recommendation.

Usage:
    from ML.recommendation.collab_filter import CollaborativeFilter

    cf = CollaborativeFilter()
    cf.fit()                          # Train on mock student data

    # Recommend for student at row index 42
    recs = cf.recommend_for_student(student_row_idx=42, top_n=5)
    print(recs)   # [("linear_regression", 0.87), ("random_forests", 0.81), ...]

    # Or provide a raw IKP vector directly
    recs = cf.recommend_for_vector(ikp_vector, top_n=5)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from ML.recommendation.matrix_factory import build_interaction_matrix
from ML.data.mock_students import SKILL_NODES

# ── Configuration ─────────────────────────────────────────────────────────────
N_COMPONENTS = 20          # Latent factors for SVD
N_SIMILAR_STUDENTS = 20   # Peer pool size (as specified in brief)
MASTERY_THRESHOLD = 0.65  # Score above which a peer is considered to have "succeeded"


class CollaborativeFilter:
    """
    SVD-based collaborative filter for personalised module recommendations.

    Attributes:
        svd:            Fitted TruncatedSVD model.
        student_factors: Latent factor matrix (N_students × N_components).
        matrix:          Raw interaction matrix.
        student_ids:     Row labels.
        module_ids:      Column labels (SKILL_NODES order).
    """

    def __init__(
        self,
        n_components: int = N_COMPONENTS,
        n_similar_students: int = N_SIMILAR_STUDENTS,
        mastery_threshold: float = MASTERY_THRESHOLD,
    ):
        self.n_components = n_components
        self.n_similar_students = n_similar_students
        self.mastery_threshold = mastery_threshold

        self.svd: TruncatedSVD | None = None
        self.student_factors: np.ndarray | None = None
        self.matrix: np.ndarray | None = None
        self.student_ids: list[str] = []
        self.module_ids: list[str] = []
        self._is_fitted = False

    def fit(self, students: list[dict] | None = None) -> "CollaborativeFilter":
        """
        Build the interaction matrix and fit the SVD decomposition.

        Args:
            students: Optional pre-generated student list. Generates fresh if None.

        Returns:
            self (for chaining)
        """
        self.matrix, self.student_ids, self.module_ids = build_interaction_matrix(students)

        # Fit SVD on the raw interaction matrix
        self.svd = TruncatedSVD(
            n_components=min(self.n_components, self.matrix.shape[1] - 1),
            algorithm="randomized",
            random_state=42,
        )
        self.student_factors = self.svd.fit_transform(self.matrix)

        # L2-normalise for cosine similarity
        self.student_factors = normalize(self.student_factors, norm="l2")

        self._is_fitted = True
        explained = self.svd.explained_variance_ratio_.sum()
        print(f"[CollabFilter] SVD fitted — {self.n_components} components explain "
              f"{explained:.1%} of variance across {len(self.student_ids)} students.")
        return self

    def _get_similar_students(self, query_vector: np.ndarray) -> list[tuple[int, float]]:
        """
        Find the N most similar students to a query latent vector.

        Args:
            query_vector: Latent factor vector for the query student (1 × n_components).

        Returns:
            List of (row_index, cosine_similarity_score) tuples, sorted desc.
        """
        query_norm = normalize(query_vector.reshape(1, -1), norm="l2")
        similarities = cosine_similarity(query_norm, self.student_factors)[0]
        # Exclude the query student itself if they're in the matrix (similarity == 1.0)
        top_indices = np.argsort(similarities)[::-1]
        results = []
        for idx in top_indices:
            if similarities[idx] >= 0.999 and len(results) == 0:
                continue  # Skip exact match (self)
            results.append((int(idx), float(similarities[idx])))
            if len(results) >= self.n_similar_students:
                break
        return results

    def _peer_success_rates(
        self,
        similar_students: list[tuple[int, float]],
        exclude_modules: set[int],
    ) -> dict[int, float]:
        """
        Calculate weighted success rates for modules among peer students.

        Args:
            similar_students: List of (row_idx, similarity_weight) pairs.
            exclude_modules:  Set of module column indices already mastered by query student.

        Returns:
            Dict mapping module_index → weighted success rate [0.0, 1.0]
        """
        module_weighted_sum = {}
        module_weight_total = {}

        for row_idx, sim_weight in similar_students:
            for mod_idx in range(len(self.module_ids)):
                if mod_idx in exclude_modules:
                    continue
                peer_score = self.matrix[row_idx, mod_idx]
                if peer_score == 0:
                    continue
                success = float(peer_score >= self.mastery_threshold)
                module_weighted_sum[mod_idx] = module_weighted_sum.get(mod_idx, 0.0) + success * sim_weight
                module_weight_total[mod_idx] = module_weight_total.get(mod_idx, 0.0) + sim_weight

        return {
            mod_idx: module_weighted_sum[mod_idx] / module_weight_total[mod_idx]
            for mod_idx in module_weighted_sum
            if module_weight_total[mod_idx] > 0
        }

    def recommend_for_student(
        self,
        student_row_idx: int,
        top_n: int = 5,
        already_mastered: set[str] | None = None,
    ) -> list[tuple[str, float]]:
        """
        Generate collaborative recommendations for an existing student by row index.

        Args:
            student_row_idx: Row index in the interaction matrix.
            top_n:           Maximum number of recommendations.
            already_mastered: Set of skill IDs to exclude from recommendations.

        Returns:
            List of (module_id, confidence_score) tuples, sorted by confidence desc.
        """
        if not self._is_fitted:
            raise RuntimeError("Call .fit() before recommend_for_student().")

        query_vector = self.student_factors[student_row_idx]
        return self._recommend(query_vector, top_n, already_mastered)

    def recommend_for_vector(
        self,
        ikp: dict[str, float],
        top_n: int = 5,
        already_mastered: set[str] | None = None,
    ) -> list[tuple[str, float]]:
        """
        Generate collaborative recommendations for a NEW student using their IKP.

        The IKP is converted to a raw interaction vector, projected into the
        SVD latent space, and then matched against the existing student pool.

        Args:
            ikp:             Dict mapping skill_id → proficiency score.
            top_n:           Maximum number of recommendations.
            already_mastered: Set of skill IDs to exclude.

        Returns:
            List of (module_id, confidence_score) tuples.
        """
        if not self._is_fitted:
            raise RuntimeError("Call .fit() before recommend_for_vector().")

        # Convert IKP dict to a raw score vector
        raw_vector = np.array(
            [ikp.get(skill, 0.0) for skill in self.module_ids],
            dtype=np.float32,
        ).reshape(1, -1)

        # Project into latent space
        latent_vector = self.svd.transform(raw_vector)[0]
        return self._recommend(latent_vector, top_n, already_mastered)

    def _recommend(
        self,
        latent_vector: np.ndarray,
        top_n: int,
        already_mastered: set[str] | None,
    ) -> list[tuple[str, float]]:
        """Internal recommendation logic shared by both recommend methods."""
        already_mastered = already_mastered or set()
        exclude_indices = {
            i for i, m in enumerate(self.module_ids) if m in already_mastered
        }

        similar_students = self._get_similar_students(latent_vector)
        success_rates = self._peer_success_rates(similar_students, exclude_indices)

        # Sort by weighted success rate
        ordered = sorted(success_rates.items(), key=lambda x: x[1], reverse=True)
        top = ordered[:top_n]

        return [(self.module_ids[mod_idx], round(score, 4)) for mod_idx, score in top]


if __name__ == "__main__":
    cf = CollaborativeFilter()
    cf.fit()

    print("\n=== Recommendations for Student #42 ===")
    recs = cf.recommend_for_student(student_row_idx=42, top_n=5)
    for module, confidence in recs:
        print(f"  {module:<30}  confidence={confidence:.4f}")

    print("\n=== Recommendations via IKP vector (cold-start demo) ===")
    sample_ikp = {
        "python_basics": 0.90,
        "data_types": 0.85,
        "control_flow": 0.80,
        "functions_scope": 0.75,
        "numpy_basics": 0.70,
    }
    recs2 = cf.recommend_for_vector(sample_ikp, top_n=5)
    for module, confidence in recs2:
        print(f"  {module:<30}  confidence={confidence:.4f}")

import sys
from pathlib import Path

# Ensure codetyhub-app workspace root is in sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

import unittest

try:
    from fastapi.testclient import TestClient
    from ML.api.main import app
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False


class TestMLAPI(unittest.TestCase):
    def setUp(self):
        if not HAS_DEPS:
            self.skipTest("Missing dependencies (fastapi/httpx). Install requirements.txt")
        self.client = TestClient(app)
        self.sample_student_profile = {
            "student_id": "STU-TEST-001",
            "ikp": {
                "proficiency_scores": {
                    "python_basics": 0.85,
                    "data_types": 0.80
                }
            },
            "engagement": {
                "current_streak": 5,
                "sessions_per_week": 4.0,
                "avg_session_minutes": 25.0
            },
            "interactions": []
        }
        self.sample_code_submission = {
            "student_id": "STU-TEST-001",
            "skill_node": "linear_regression",
            "code_text": """
import numpy as np

def train_linear_model(X, y):
    X_b = np.c_[np.ones((len(X), 1)), X]
    theta_best = np.linalg.inv(X_b.T.dot(X_b)).dot(X_b.T).dot(y)
    return theta_best
"""
        }

    def test_health_endpoints(self):
        """Test health check endpoints / and /health."""
        res_root = self.client.get("/")
        self.assertEqual(res_root.status_code, 200)
        data = res_root.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["service"], "CodetyHub ML API")

        res_health = self.client.get("/health")
        self.assertEqual(res_health.status_code, 200)
        self.assertEqual(res_health.json()["status"], "ok")

    def test_pathway_recommend(self):
        """Test pathway recommendation endpoint."""
        payload = {
            "student_id": "STU-101",
            "ikp": {
                "proficiency_scores": {
                    "python_basics": 0.9,
                    "numpy_basics": 0.8,
                    "pandas_basics": 0.4
                }
            },
            "top_n": 3
        }
        res = self.client.post("/pathway/recommend", json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("student_id", data)
        self.assertIn("recommendations", data)
        self.assertIsInstance(data["recommendations"], list)

    def test_gamification_dropout_risk(self):
        """Test gamification dropout risk evaluation endpoint."""
        res = self.client.post("/gamification/risk", json=self.sample_student_profile)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("risk_score", data)
        self.assertIn("risk_band", data)
        self.assertIn(data["risk_band"], ["LOW", "MEDIUM", "HIGH"])
        self.assertIn("interventions", data)

    def test_code_review_evaluate(self):
        """Test code review evaluation endpoint."""
        res = self.client.post("/code-review/evaluate", json=self.sample_code_submission)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("student_id", data)
        self.assertIn("vss", data)
        self.assertTrue(0.0 <= data["vss"] <= 100.0)
        self.assertIn("feedback", data)
        self.assertIn("dimension_scores", data)


if __name__ == "__main__":
    unittest.main()

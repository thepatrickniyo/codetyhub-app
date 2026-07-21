import sys
from pathlib import Path

# Ensure codetyhub-app workspace root is in sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

import unittest

try:
    from ML.code_review.codebert_evaluator import CodeBertEvaluator
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False


class TestCodeReview(unittest.TestCase):
    def setUp(self):
        if not HAS_DEPS:
            self.skipTest("Missing ML dependencies (requests/numpy). Install requirements.txt")
        self.sample_code_submission = {
            "student_id": "STU-TEST-001",
            "skill_node": "linear_regression",
            "code_text": """
import numpy as np

def train_linear_model(X, y):
    \"\"\"Trains a basic linear regression model using normal equation.\"\"\"
    X_b = np.c_[np.ones((len(X), 1)), X]
    theta_best = np.linalg.inv(X_b.T.dot(X_b)).dot(X_b.T).dot(y)
    return theta_best
"""
        }

    def test_codebert_evaluator_scoring(self):
        """Test CodeBertEvaluator scoring and rubric output."""
        evaluator = CodeBertEvaluator()
        result = evaluator.evaluate(
            student_id=self.sample_code_submission["student_id"],
            skill_node=self.sample_code_submission["skill_node"],
            code_text=self.sample_code_submission["code_text"]
        )
        self.assertTrue(0.0 <= result.vss <= 100.0)
        self.assertIn("code_correctness", result.dimension_scores)
        self.assertIn("structural_elegance", result.dimension_scores)
        self.assertIn("contextual_alignment", result.dimension_scores)
        self.assertIn("documentation", result.dimension_scores)
        self.assertIsInstance(result.feedback, dict)


if __name__ == "__main__":
    unittest.main()

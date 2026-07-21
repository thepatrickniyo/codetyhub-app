import sys
from pathlib import Path

# Ensure codetyhub-app workspace root is in sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

import unittest

try:
    from ML.gamification.dropout_predictor import DropoutPredictor
    from ML.gamification.feature_engineering import extract_features, FEATURE_NAMES
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False


class TestGamification(unittest.TestCase):
    def setUp(self):
        if not HAS_DEPS:
            self.skipTest("Missing ML dependencies (numpy/xgboost). Install requirements.txt")
        self.sample_student_profile = {
            "student_id": "STU-TEST-001",
            "days_inactive": 1,
            "completed_lessons": 12,
            "quiz_score_avg": 85.5,
            "forum_posts_count": 4,
            "submission_delay_hours": 2.5,
            "total_study_time_hours": 18.0,
            "streak_days": 5
        }

    def test_feature_extraction(self):
        """Test feature engineering transformation into expected feature vector."""
        features = extract_features(self.sample_student_profile)
        self.assertEqual(len(features), len(FEATURE_NAMES))
        self.assertIsInstance(features, (list, tuple))

    def test_dropout_predictor_inference(self):
        """Test XGBoost dropout predictor risk inference."""
        predictor = DropoutPredictor()
        result = predictor.predict(self.sample_student_profile)
        self.assertTrue(hasattr(result, "risk_score"))
        self.assertTrue(0.0 <= result.risk_score <= 1.0)
        self.assertIn(result.risk_band, ["LOW", "MEDIUM", "HIGH"])
        self.assertIsInstance(result.interventions, list)


if __name__ == "__main__":
    unittest.main()

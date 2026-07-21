import pytest
from fastapi.testclient import TestClient
import sys
from pathlib import Path

# Add workspace root to sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from ML.api.main import app

@pytest.fixture
def client():
    """FastAPI TestClient fixture."""
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture
def sample_student_profile():
    return {
        "student_id": "STU-TEST-001",
        "days_inactive": 1,
        "completed_lessons": 12,
        "quiz_score_avg": 85.5,
        "forum_posts_count": 4,
        "submission_delay_hours": 2.5,
        "total_study_time_hours": 18.0,
        "streak_days": 5
    }

@pytest.fixture
def sample_code_submission():
    return {
        "student_id": "STU-TEST-001",
        "skill_node": "linear_regression",
        "code_text": """
import numpy as np

def train_linear_model(X, y):
    \"\"\"Trains a basic linear regression model using normal equation.\"\"\"
    # Add intercept column
    X_b = np.c_[np.ones((len(X), 1)), X]
    # Calculate best parameters
    theta_best = np.linalg.inv(X_b.T.dot(X_b)).dot(X_b.T).dot(y)
    return theta_best
"""
    }

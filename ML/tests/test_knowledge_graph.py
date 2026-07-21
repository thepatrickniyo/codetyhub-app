import sys
from pathlib import Path

# Ensure codetyhub-app workspace root is in sys.path
root_dir = Path(__file__).resolve().parents[2]
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

import unittest

try:
    from ML.knowledge_graph.path_engine import PathEngine, PathResult
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False


class TestKnowledgeGraph(unittest.TestCase):
    def setUp(self):
        if not HAS_DEPS:
            self.skipTest("Missing ML dependencies (networkx). Install requirements.txt")

    def test_path_engine_initialisation(self):
        """Test PathEngine graph loading and structure."""
        engine = PathEngine()
        self.assertIsNotNone(engine.G)
        self.assertGreater(len(engine.G.nodes), 0)

    def test_path_engine_recommendation(self):
        """Test recommendation logic based on mastered prerequisites."""
        engine = PathEngine()
        ikp = {
            "python_basics": 0.85,
            "linear_algebra_basics": 0.70
        }
        result = engine.recommend(ikp, top_n=3)
        self.assertIsInstance(result, PathResult)
        self.assertIn("python_basics", result.mastered)
        self.assertIn("linear_algebra_basics", result.mastered)
        self.assertLessEqual(len(result.recommended), 3)


if __name__ == "__main__":
    unittest.main()

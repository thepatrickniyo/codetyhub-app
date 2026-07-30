/// ml_service.dart
/// ----------------
/// HTTP client that wraps every Node.js ML bridge endpoint.
///
/// Architecture:
///   Flutter controllers  →  MlService  →  Node bridge (:3001)
///                                          └── FastAPI ML (:8000)
///
/// All methods return typed Dart model objects or null on failure.
/// Errors are logged to console and never bubble up as exceptions —
/// the app always degrades gracefully to mock/local state.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';
import '../models/ml_models.dart';

class MlService {
  MlService({String? baseUrl, String? bearerToken})
      : _base = baseUrl ?? bridgeUrl,
        _token = bearerToken ?? 'DEV-anonymous-codetyhub';

  final String _base;
  final String _token;

  // ── Internal helpers ──────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_base$path');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _log('POST $path → ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      _log('POST $path failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _get(String path, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_base$path');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _log('GET $path → ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      _log('GET $path failed: $e');
      return null;
    }
  }

  void _log(String msg) => print('[MlService] $msg');

  // ── Pathway Recommendation ─────────────────────────────────────────────────

  /// Get personalised skill pathway recommendations using hybrid SVD + DAG engine.
  ///
  /// [ikpScores] maps skill node IDs → proficiency scores in [0.0, 1.0].
  /// Example: `{'python_basics': 0.9, 'linear_regression': 0.3}`
  Future<PathwayRecommendResponse?> recommendPathway({
    required String studentId,
    required Map<String, double> ikpScores,
    int topN = 5,
    bool includeCollaborative = true,
  }) async {
    final body = {
      'student_id': studentId,
      'ikp': {'proficiency_scores': ikpScores},
      'top_n': topN,
      'include_collaborative': includeCollaborative,
    };
    final json = await _post('/api/pathway/recommend', body);
    if (json == null) return null;
    try {
      return PathwayRecommendResponse.fromJson(json);
    } catch (e) {
      _log('recommendPathway parse error: $e');
      return null;
    }
  }

  /// Get prerequisite graph info for a specific skill node.
  Future<Map<String, dynamic>?> getSkillPrerequisites(String skillId) async {
    return _get('/api/pathway/graph/prerequisites/$skillId');
  }

  /// Get overall knowledge graph statistics.
  Future<Map<String, dynamic>?> getGraphInfo() async {
    return _get('/api/pathway/graph/info');
  }

  // ── Gamification / Dropout Risk ────────────────────────────────────────────

  /// Run XGBoost dropout risk inference for a student.
  ///
  /// Risk bands:
  ///   LOW    (< 0.35) → no intervention
  ///   MEDIUM (0.35–0.65) → streak reminders, leaderboard highlights
  ///   HIGH   (≥ 0.65) → Streak Recovery Token, bonus XP challenge, peer study room
  ///
  /// [engagement] maps engagement metric names → values. Supported keys:
  ///   current_streak, streak_delta_7d, total_xp, xp_trend_slope,
  ///   leaderboard_checks_30d, challenge_refusals_30d,
  ///   sessions_per_week, avg_session_minutes
  Future<GamificationRiskResponse?> predictDropoutRisk({
    required String studentId,
    required Map<String, double> ikpScores,
    required Map<String, dynamic> engagement,
    List<Map<String, dynamic>> interactions = const [],
  }) async {
    final body = {
      'student_id': studentId,
      'ikp': {'proficiency_scores': ikpScores},
      'engagement': engagement,
      'interactions': interactions,
    };
    final json = await _post('/api/gamification/risk', body);
    if (json == null) return null;
    try {
      return GamificationRiskResponse.fromJson(json);
    } catch (e) {
      _log('predictDropoutRisk parse error: $e');
      return null;
    }
  }

  // ── Code Review / VSS ─────────────────────────────────────────────────────

  /// Submit code for CodeBERT evaluation and get a Verified Skill Score.
  Future<CodeReviewResponse?> evaluateCode({
    required String studentId,
    required String skillNode,
    required String codeText,
  }) async {
    final body = {
      'student_id': studentId,
      'skill_node': skillNode,
      'code_text': codeText,
    };
    final json = await _post('/api/code-review/evaluate', body);
    if (json == null) return null;
    try {
      return CodeReviewResponse.fromJson(json);
    } catch (e) {
      _log('evaluateCode parse error: $e');
      return null;
    }
  }

  /// Get the VSS talent leaderboard.
  Future<List<MlLeaderboardEntry>> getLeaderboard({int limit = 20}) async {
    final json = await _get(
      '/api/code-review/leaderboard',
      queryParams: {'limit': '$limit'},
    );
    if (json == null) return [];
    try {
      final data = json['data'] as List? ?? [];
      return data
          .map((e) => MlLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('getLeaderboard parse error: $e');
      return [];
    }
  }

  /// Get the CodeBERT evaluation rubric and dimension weights.
  Future<Map<String, dynamic>?> getEvaluationRubric() async {
    return _get('/api/code-review/rubric');
  }

  // ── Authentication & Progress Persistence ──────────────────────────────────

  /// Register a new student account in PostgreSQL.
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    return _post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// Login existing student against PostgreSQL & fetch progress.
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    return _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  /// Retrieve student's persisted progress from PostgreSQL.
  Future<Map<String, dynamic>?> fetchUserProgress(String userId) async {
    return _get('/api/auth/progress/$userId');
  }

  /// Persist student's XP, streak, and completed lessons to PostgreSQL.
  Future<bool> syncUserProgress({
    required String userId,
    required int xp,
    required int streak,
    required List<String> completedLessons,
    List<String> completedQuizzes = const [],
    Map<String, double> ikpScores = const {},
    List<String> badges = const [],
  }) async {
    final result = await _post('/api/auth/progress/sync', {
      'user_id': userId,
      'xp': xp,
      'streak': streak,
      'completed_lessons': completedLessons,
      'completed_quizzes': completedQuizzes,
      'ikp_scores': ikpScores,
      'badges': badges,
    });
    return result?['success'] == true;
  }

  // ── Health check ──────────────────────────────────────────────────────────

  /// Returns true if the Node bridge (and by extension the ML service) is reachable.
  Future<bool> isReachable() async {
    try {
      final uri = Uri.parse('$_base/health');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

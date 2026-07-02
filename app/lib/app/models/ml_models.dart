/// ml_models.dart
/// ---------------
/// Dart model classes that mirror the CodetyHub ML API response schemas.
///
/// These are pure data-transfer objects — they parse the JSON returned
/// by the Node bridge (which proxies the FastAPI ML microservice).

// ── Pathway Recommendation ─────────────────────────────────────────────────────

class SkillRecommendation {
  const SkillRecommendation({
    required this.skillId,
    required this.label,
    required this.hybridScore,
    this.ruleBasedPriority,
    this.collaborativeConfidence,
  });

  final String skillId;
  final String label;
  final double hybridScore;
  final double? ruleBasedPriority;
  final double? collaborativeConfidence;

  factory SkillRecommendation.fromJson(Map<String, dynamic> json) =>
      SkillRecommendation(
        skillId: json['skill_id'] as String,
        label: json['label'] as String,
        hybridScore: (json['hybrid_score'] as num).toDouble(),
        ruleBasedPriority: json['rule_based_priority'] != null
            ? (json['rule_based_priority'] as num).toDouble()
            : null,
        collaborativeConfidence: json['collaborative_confidence'] != null
            ? (json['collaborative_confidence'] as num).toDouble()
            : null,
      );
}

class PathwayRecommendResponse {
  const PathwayRecommendResponse({
    required this.studentId,
    required this.mastered,
    required this.inProgress,
    required this.recommendations,
    required this.totalSkills,
    required this.completionPct,
  });

  final String studentId;
  final List<String> mastered;
  final List<String> inProgress;
  final List<SkillRecommendation> recommendations;
  final int totalSkills;
  final double completionPct;

  factory PathwayRecommendResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PathwayRecommendResponse(
      studentId: data['student_id'] as String,
      mastered: List<String>.from(data['mastered'] as List),
      inProgress: List<String>.from(data['in_progress'] as List),
      recommendations: (data['recommendations'] as List)
          .map((e) => SkillRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSkills: data['total_skills'] as int,
      completionPct: (data['completion_pct'] as num).toDouble(),
    );
  }
}

// ── Gamification / Dropout Risk ───────────────────────────────────────────────

class MlIntervention {
  const MlIntervention({
    required this.type,
    required this.title,
    required this.description,
    this.payload = const {},
  });

  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> payload;

  factory MlIntervention.fromJson(Map<String, dynamic> json) => MlIntervention(
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        payload: Map<String, dynamic>.from(
            (json['payload'] as Map<dynamic, dynamic>?) ?? {}),
      );
}

class GamificationRiskResponse {
  const GamificationRiskResponse({
    required this.studentId,
    required this.riskScore,
    required this.riskBand,
    required this.interventions,
    required this.topRiskFactors,
  });

  final String studentId;

  /// Dropout probability [0.0 – 1.0]
  final double riskScore;

  /// "LOW" | "MEDIUM" | "HIGH"
  final String riskBand;

  final List<MlIntervention> interventions;
  final List<List<dynamic>> topRiskFactors;

  bool get isHighRisk => riskBand == 'HIGH';
  bool get isMediumRisk => riskBand == 'MEDIUM';

  factory GamificationRiskResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return GamificationRiskResponse(
      studentId: data['student_id'] as String,
      riskScore: (data['risk_score'] as num).toDouble(),
      riskBand: data['risk_band'] as String,
      interventions: (data['interventions'] as List)
          .map((e) => MlIntervention.fromJson(e as Map<String, dynamic>))
          .toList(),
      topRiskFactors: (data['top_risk_factors'] as List)
          .map((e) => List<dynamic>.from(e as List))
          .toList(),
    );
  }
}

// ── Code Review / VSS ─────────────────────────────────────────────────────────

class CodeReviewResponse {
  const CodeReviewResponse({
    required this.studentId,
    required this.skillNode,
    required this.vss,
    required this.dimensionScores,
    required this.feedback,
    required this.submissionHash,
    this.leaderboardRank,
  });

  final String studentId;
  final String skillNode;

  /// Verified Skill Score [0.0 – 100.0]
  final double vss;
  final Map<String, double> dimensionScores;
  final Map<String, String> feedback;
  final String submissionHash;
  final int? leaderboardRank;

  factory CodeReviewResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CodeReviewResponse(
      studentId: data['student_id'] as String,
      skillNode: data['skill_node'] as String,
      vss: (data['vss'] as num).toDouble(),
      dimensionScores: Map<String, double>.fromEntries(
        (data['dimension_scores'] as Map<String, dynamic>)
            .entries
            .map((e) => MapEntry(e.key, (e.value as num).toDouble())),
      ),
      feedback: Map<String, String>.from(
          data['feedback'] as Map<dynamic, dynamic>),
      submissionHash: data['submission_hash'] as String,
      leaderboardRank: data['leaderboard_rank'] as int?,
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

class MlLeaderboardEntry {
  const MlLeaderboardEntry({
    required this.studentId,
    required this.vss,
    required this.rank,
  });

  final String studentId;
  final double vss;
  final int rank;

  factory MlLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      MlLeaderboardEntry(
        studentId: json['student_id'] as String,
        vss: (json['vss'] as num).toDouble(),
        rank: json['rank'] as int,
      );
}

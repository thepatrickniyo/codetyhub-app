import 'package:flutter_test/flutter_test.dart';
import 'package:codetyhub_app/app/models/gamification_state.dart';
import 'package:codetyhub_app/app/models/ml_models.dart';
import 'package:codetyhub_app/app/models/badge_model.dart';
import 'package:codetyhub_app/app/models/user_model.dart';

void main() {
  group('GamificationState Unit Tests', () {
    test('Default values and level calculations', () {
      const state = GamificationState();
      expect(state.xp, equals(0));
      expect(state.level, equals(1));
      expect(state.levelProgress, equals(0.0));
      expect(state.streak, equals(0));
    });

    test('XP progression level math', () {
      const state = GamificationState(xp: 1250);
      expect(state.level, equals(3)); // (1250/500).floor() + 1 = 3
      expect(state.xpForNextLevel, equals(1500));
      expect(state.levelProgress, equals(250 / 500));
    });

    test('copyWith state update immutability', () {
      const state = GamificationState(xp: 100, streak: 2);
      final updated = state.copyWith(xp: 250, streak: 3);
      expect(updated.xp, equals(250));
      expect(updated.streak, equals(3));
      expect(state.xp, equals(100)); // original untouched
    });
  });

  group('ML Models Deserialization Tests', () {
    test('SkillRecommendation.fromJson', () {
      final json = {
        'skill_id': 'python_basics',
        'label': 'Python Fundamentals',
        'hybrid_score': 0.95,
        'rule_based_priority': 0.90,
        'collaborative_confidence': 0.88,
      };
      final recommendation = SkillRecommendation.fromJson(json);
      expect(recommendation.skillId, equals('python_basics'));
      expect(recommendation.label, equals('Python Fundamentals'));
      expect(recommendation.hybridScore, equals(0.95));
      expect(recommendation.ruleBasedPriority, equals(0.90));
    });

    test('GamificationRiskResponse.fromJson', () {
      final json = {
        'student_id': 'STU-001',
        'risk_score': 0.72,
        'risk_band': 'HIGH',
        'interventions': [
          {
            'type': 'STREAK_FREEZE',
            'title': 'Streak Saver Activated',
            'description': 'Protect your learning streak.',
            'action': 'CLAIM_FREEZE'
          }
        ],
        'top_risk_factors': [
          ['days_inactive', 5]
        ]
      };
      final risk = GamificationRiskResponse.fromJson(json);
      expect(risk.studentId, equals('STU-001'));
      expect(risk.riskScore, equals(0.72));
      expect(risk.riskBand, equals('HIGH'));
      expect(risk.interventions.length, equals(1));
      expect(risk.interventions.first.title, equals('Streak Saver Activated'));
      expect(risk.topRiskFactors.length, equals(1));
    });
  });

  group('UserModel Unit Tests', () {
    test('UserModel properties and JSON serialization', () {
      const user = UserModel(
        id: '1',
        name: 'Jane Doe',
        email: 'jane@example.com',
        password: 'secretpassword',
      );
      expect(user.id, equals('1'));
      expect(user.name, equals('Jane Doe'));
      expect(user.email, equals('jane@example.com'));

      final json = user.toJson();
      expect(json['id'], equals('1'));
      expect(json['email'], equals('jane@example.com'));

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.name, equals('Jane Doe'));
    });
  });
}

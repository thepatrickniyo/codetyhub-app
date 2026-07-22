import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codetyhub_app/app/models/badge_model.dart';
import 'package:codetyhub_app/app/models/course_model.dart';
import 'package:codetyhub_app/app/models/gamification_state.dart';
import 'package:codetyhub_app/app/models/leaderboard_model.dart';
import 'package:codetyhub_app/app/models/lesson_model.dart';
import 'package:codetyhub_app/app/models/ml_models.dart';
import 'package:codetyhub_app/app/models/pathway_model.dart';
import 'package:codetyhub_app/app/models/quiz_model.dart';
import 'package:codetyhub_app/app/models/user_model.dart';

void main() {
  group('BadgeModel Tests', () {
    test('Constructs BadgeModel correctly', () {
      const badge = BadgeModel(
        id: 'b1',
        title: 'First Code',
        description: 'Completed 1st lesson',
        icon: Icons.star,
        color: Colors.amber,
        xpRequired: 100,
      );

      expect(badge.id, equals('b1'));
      expect(badge.title, equals('First Code'));
      expect(badge.description, equals('Completed 1st lesson'));
      expect(badge.icon, equals(Icons.star));
      expect(badge.color, equals(Colors.amber));
      expect(badge.xpRequired, equals(100));
    });
  });

  group('CourseModel Tests', () {
    test('Constructs CourseModel correctly', () {
      const course = CourseModel(
        id: 'c1',
        title: 'Python Essentials',
        description: 'Learn fundamentals',
        duration: '2h 30m',
        level: 'Beginner',
        lessons: 5,
        rating: 4.8,
      );

      expect(course.id, equals('c1'));
      expect(course.title, equals('Python Essentials'));
      expect(course.description, equals('Learn fundamentals'));
      expect(course.duration, equals('2h 30m'));
      expect(course.level, equals('Beginner'));
      expect(course.lessons, equals(5));
      expect(course.rating, equals(4.8));
    });
  });

  group('LeaderboardEntry Tests', () {
    test('Constructs LeaderboardEntry correctly', () {
      const entry = LeaderboardEntry(
        rank: 1,
        name: 'Alex Johnson',
        avatarInitials: 'AJ',
        points: 4500,
        pathwaysCompleted: 3,
        streak: 14,
      );

      expect(entry.rank, equals(1));
      expect(entry.name, equals('Alex Johnson'));
      expect(entry.avatarInitials, equals('AJ'));
      expect(entry.points, equals(4500));
      expect(entry.pathwaysCompleted, equals(3));
      expect(entry.streak, equals(14));
    });
  });

  group('LessonModel Tests', () {
    test('Constructs LessonModel with default code language', () {
      const lesson = LessonModel(
        title: 'Intro to Variables',
        duration: '15m',
        body: 'Variables store values.',
        codeSnippet: 'x = 10',
      );

      expect(lesson.title, equals('Intro to Variables'));
      expect(lesson.duration, equals('15m'));
      expect(lesson.body, equals('Variables store values.'));
      expect(lesson.codeSnippet, equals('x = 10'));
      expect(lesson.codeLanguage, equals('python'));
    });
  });

  group('PathwayModel Tests', () {
    const course1 = CourseModel(
      id: 'c1',
      title: 'Course 1',
      description: 'Desc 1',
      duration: '1h',
      level: 'Beginner',
      lessons: 3,
      rating: 4.5,
    );

    test('courseCount getter returns number of courses', () {
      const pathway = PathwayModel(
        id: 'ml-fundamentals',
        title: 'ML Fundamentals',
        description: 'Intro to ML',
        icon: 'ml-fundamentals',
        colorIndex: 0,
        courses: [course1],
        totalHours: 10,
      );

      expect(pathway.courseCount, equals(1));
    });

    test('iconData switch cases return expected IconData', () {
      const icons = [
        'ml-fundamentals',
        'brain',
        'deep-learning',
        'microscope',
        'nlp',
        'chat',
        'computer-vision',
        'eye',
        'generative-ai',
        'sparkles',
        'mlops',
        'rocket',
        'unknown_icon',
      ];

      for (final icon in icons) {
        final pw = PathwayModel(
          id: 'test',
          title: 'Test',
          description: 'Test',
          icon: icon,
          colorIndex: 0,
          courses: const [],
          totalHours: 5,
        );
        expect(pw.iconData, isA<IconData>());
      }
    });

    test('imageUrl switch cases return valid Unsplash URLs', () {
      const ids = [
        'ml-fundamentals',
        'deep-learning',
        'nlp',
        'computer-vision',
        'generative-ai',
        'mlops',
        'default_pathway',
      ];

      for (final id in ids) {
        final pw = PathwayModel(
          id: id,
          title: 'Test',
          description: 'Test',
          icon: 'brain',
          colorIndex: 0,
          courses: const [],
          totalHours: 5,
        );
        expect(pw.imageUrl.startsWith('https://images.unsplash.com/'), isTrue);
      }
    });
  });

  group('QuizQuestion Tests', () {
    test('Constructs QuizQuestion correctly', () {
      const q = QuizQuestion(
        question: 'What is Python?',
        hint: 'High level language',
        options: ['Language', 'Snake', 'Car', 'Food'],
        optionScores: [
          {'ml-fundamentals': 5},
          {'ml-fundamentals': 0},
          {'ml-fundamentals': 0},
          {'ml-fundamentals': 0},
        ],
      );

      expect(q.question, equals('What is Python?'));
      expect(q.hint, equals('High level language'));
      expect(q.options.length, equals(4));
      expect(q.optionScores.first['ml-fundamentals'], equals(5));
    });
  });

  group('GamificationState Tests', () {
    test('Default values and calculations', () {
      const state = GamificationState();
      expect(state.xp, equals(0));
      expect(state.level, equals(1));
      expect(state.levelProgress, equals(0.0));
      expect(state.streak, equals(0));
    });

    test('XP level progress math', () {
      const state = GamificationState(xp: 1250);
      expect(state.level, equals(3));
      expect(state.xpForNextLevel, equals(1500));
      expect(state.levelProgress, equals(250 / 500));
    });

    test('copyWith immutability', () {
      const state = GamificationState(xp: 100, streak: 2);
      final updated = state.copyWith(xp: 250, streak: 3);
      expect(updated.xp, equals(250));
      expect(updated.streak, equals(3));
      expect(state.xp, equals(100));
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
      expect(recommendation.collaborativeConfidence, equals(0.88));
    });

    test('PathwayRecommendResponse.fromJson', () {
      final json = {
        'student_id': 'STU-100',
        'mastered': ['python_basics'],
        'in_progress': ['data_types'],
        'recommendations': [
          {
            'skill_id': 'control_flow',
            'label': 'Control Flow',
            'hybrid_score': 0.85,
          }
        ],
        'total_skills': 10,
        'completion_pct': 0.1,
      };
      final response = PathwayRecommendResponse.fromJson(json);
      expect(response.studentId, equals('STU-100'));
      expect(response.mastered, equals(['python_basics']));
      expect(response.recommendations.length, equals(1));
    });

    test('GamificationRiskResponse.fromJson & helpers', () {
      final json = {
        'student_id': 'STU-001',
        'risk_score': 0.72,
        'risk_band': 'HIGH',
        'interventions': [
          {
            'type': 'STREAK_FREEZE',
            'title': 'Streak Saver Activated',
            'description': 'Protect your learning streak.',
            'action': 'CLAIM_FREEZE',
            'payload': {'days': 1}
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
      expect(risk.isHighRisk, isTrue);
      expect(risk.isMediumRisk, isFalse);
      expect(risk.interventions.first.type, equals('STREAK_FREEZE'));
      expect(risk.interventions.first.payload['days'], equals(1));
    });

    test('CodeReviewResponse.fromJson', () {
      final json = {
        'student_id': 'STU-001',
        'skill_node': 'linear_regression',
        'vss': 88.5,
        'dimension_scores': {'code_correctness': 0.9},
        'feedback': {'code_correctness': 'Great job'},
        'submission_hash': 'abc123hash',
        'leaderboard_rank': 2
      };
      final codeReview = CodeReviewResponse.fromJson(json);
      expect(codeReview.studentId, equals('STU-001'));
      expect(codeReview.vss, equals(88.5));
      expect(codeReview.leaderboardRank, equals(2));
    });
  });

  group('UserModel Tests', () {
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

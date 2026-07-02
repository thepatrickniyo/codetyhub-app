import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/app_config.dart';
import '../data/ml_service.dart';
import '../models/badge_model.dart';
import '../models/ml_models.dart';

class GamificationController extends GetxController {
  // ── Observable state ──────────────────────────────────────────────────────
  final RxInt xp = 2340.obs; // Seed with some XP
  final RxInt streak = 7.obs;
  final RxSet<String> completedLessons = <String>{}.obs;
  final RxSet<String> completedCourses = <String>{}.obs;
  final RxList<BadgeModel> unlockedBadges = <BadgeModel>[].obs;

  /// Badge just unlocked — shown as overlay once then cleared.
  final Rx<BadgeModel?> newlyUnlocked = Rx<BadgeModel?>(null);

  // ── XP toast signal ───────────────────────────────────────────────────────
  final RxInt lastXpAward = 0.obs;
  final RxBool showXpToast = false.obs;

  // ── ML Dropout Risk ───────────────────────────────────────────────────────
  final Rx<GamificationRiskResponse?> latestRisk = Rx<GamificationRiskResponse?>(null);
  final RxBool isFetchingRisk = false.obs;

  /// Latest ML-driven interventions (populated when risk is HIGH/MEDIUM).
  List<MlIntervention> get mlInterventions => latestRisk.value?.interventions ?? [];
  String get riskBand => latestRisk.value?.riskBand ?? 'LOW';
  double get riskScore => latestRisk.value?.riskScore ?? 0.0;

  // ── ML Service ────────────────────────────────────────────────────────────
  late final MlService _ml;

  @override
  void onInit() {
    super.onInit();
    final storage = Get.find<GetStorage>();
    final user = storage.read<Map<dynamic, dynamic>>('current_user');
    final userId = user?['id']?.toString() ?? 'anonymous';
    _ml = MlService(
      baseUrl: bridgeUrl,
      bearerToken: devBearerToken(userId),
    );
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  int get level => (xp.value ~/ 500) + 1;
  int get xpInLevel => xp.value % 500;
  double get levelProgress => xpInLevel / 500;
  String get xpDisplay => '${xp.value} XP';
  String get rankDisplay => '#12';

  // ── All possible badges ───────────────────────────────────────────────────
  static final List<BadgeModel> _allBadges = [
    const BadgeModel(
      id: 'first_lesson',
      title: 'First Step',
      description: 'Completed your very first lesson',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF3B82F6),
      xpRequired: 0,
    ),
    const BadgeModel(
      id: 'five_lessons',
      title: 'On a Roll',
      description: 'Completed 5 lessons',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF6B35),
      xpRequired: 0,
    ),
    const BadgeModel(
      id: 'first_course',
      title: 'Course Conqueror',
      description: 'Completed your first full course',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFFBBF24),
      xpRequired: 0,
    ),
    const BadgeModel(
      id: 'streak_7',
      title: '7-Day Warrior',
      description: 'Maintained a 7-day learning streak',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF8B5CF6),
      xpRequired: 0,
    ),
    const BadgeModel(
      id: 'xp_1000',
      title: 'XP Hunter',
      description: 'Earned 1000 XP points',
      icon: Icons.star_rounded,
      color: Color(0xFF22C55E),
      xpRequired: 1000,
    ),
    const BadgeModel(
      id: 'xp_5000',
      title: 'XP Master',
      description: 'Earned 5000 XP points',
      icon: Icons.diamond_rounded,
      color: Color(0xFF06B6D4),
      xpRequired: 5000,
    ),
  ];

  List<BadgeModel> get lockedBadges => _allBadges
      .where((b) => !unlockedBadges.any((u) => u.id == b.id))
      .toList();

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Call when a student completes a lesson.
  /// [lessonKey] = '${courseId}:${lessonIndex}'
  void completeLesson(String lessonKey, String courseId) {
    if (completedLessons.contains(lessonKey)) return;
    completedLessons.add(lessonKey);

    // Award XP
    _awardXp(50);

    // Check lesson-count badges
    if (completedLessons.length == 1) _unlockBadge('first_lesson');
    if (completedLessons.length == 5) _unlockBadge('five_lessons');

    // Run ML dropout risk assessment asynchronously
    _runDropoutRiskAssessment();
  }

  /// Call when all lessons in a course are done.
  void completeCourse(String courseId) {
    if (completedCourses.contains(courseId)) return;
    completedCourses.add(courseId);
    _awardXp(200);
    if (completedCourses.length == 1) _unlockBadge('first_course');

    // Re-run risk assessment after course completion
    _runDropoutRiskAssessment();
  }

  /// Fetch dropout risk from the ML service and update [latestRisk].
  /// Fires-and-forgets — never blocks the UI.
  Future<void> _runDropoutRiskAssessment() async {
    if (isFetchingRisk.value) return; // Debounce
    isFetchingRisk.value = true;

    try {
      final storage = Get.find<GetStorage>();
      final user = storage.read<Map<dynamic, dynamic>>('current_user');
      final studentId = user?['id']?.toString() ?? 'anonymous';

      // Build engagement metrics from current observable state
      final engagement = {
        'current_streak': streak.value.toDouble(),
        'streak_delta_7d': 0.0,
        'total_xp': xp.value.toDouble(),
        'xp_trend_slope': 0.0,
        'leaderboard_checks_30d': 0.0,
        'challenge_refusals_30d': 0.0,
        'sessions_per_week': 3.5,
        'avg_session_minutes': 25.0,
      };

      // Build a minimal IKP from completed lesson keys
      // (lesson completion implies baseline proficiency for those modules)
      final ikp = <String, double>{};
      for (final key in completedLessons) {
        final parts = key.split(':');
        if (parts.isNotEmpty) {
          ikp[parts[0]] = 0.7; // Baseline mastery score for completed modules
        }
      }
      if (ikp.isEmpty) ikp['python_basics'] = 0.5; // Always send at least one skill

      final result = await _ml.predictDropoutRisk(
        studentId: studentId,
        ikpScores: ikp,
        engagement: engagement,
      );

      if (result != null) {
        latestRisk.value = result;
        print('[GamificationController] Risk: ${result.riskBand} (${result.riskScore.toStringAsFixed(2)})');

        // Log ML-driven interventions if high risk
        if (result.isHighRisk) {
          print('[GamificationController] HIGH RISK — interventions: '
              '${result.interventions.map((i) => i.type).join(', ')}');
        }
      }
    } catch (e) {
      print('[GamificationController] Risk assessment error: $e');
    } finally {
      isFetchingRisk.value = false;
    }
  }

  void _awardXp(int amount) {
    final oldLevel = level;
    xp.value += amount;
    lastXpAward.value = amount;
    showXpToast.value = true;
    Future.delayed(const Duration(seconds: 3), () => showXpToast.value = false);

    // XP threshold badges
    for (final b in _allBadges.where((b) => b.xpRequired > 0)) {
      if (xp.value >= b.xpRequired && !unlockedBadges.any((u) => u.id == b.id)) {
        _unlockBadge(b.id);
      }
    }

    // Level-up check (suppress — just log)
    if (level > oldLevel) {
      // Could trigger level-up animation here
    }
  }

  void _unlockBadge(String badgeId) {
    final badge = _allBadges.firstWhereOrNull((b) => b.id == badgeId);
    if (badge == null) return;
    if (unlockedBadges.any((b) => b.id == badgeId)) return;
    unlockedBadges.add(badge);
    newlyUnlocked.value = badge;
    // Auto-clear after animation
    Future.delayed(const Duration(seconds: 4), () => newlyUnlocked.value = null);
  }

  void clearBadgeOverlay() => newlyUnlocked.value = null;
}

import 'badge_model.dart';

class GamificationState {
  const GamificationState({
    this.xp = 0,
    this.streak = 0,
    this.completedLessons = const {},
    this.completedCourses = const {},
    this.unlockedBadges = const [],
  });

  final int xp;
  final int streak;
  final Set<String> completedLessons;
  final Set<String> completedCourses;
  final List<BadgeModel> unlockedBadges;

  int get level => (xp / 500).floor() + 1;
  int get xpForNextLevel => (level * 500);
  double get levelProgress => (xp % 500) / 500;

  GamificationState copyWith({
    int? xp,
    int? streak,
    Set<String>? completedLessons,
    Set<String>? completedCourses,
    List<BadgeModel>? unlockedBadges,
  }) {
    return GamificationState(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      completedLessons: completedLessons ?? this.completedLessons,
      completedCourses: completedCourses ?? this.completedCourses,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatarInitials,
    required this.points,
    required this.pathwaysCompleted,
    required this.streak,
  });

  final int rank;
  final String name;
  final String avatarInitials;
  final int points;
  final int pathwaysCompleted;
  final int streak;
}

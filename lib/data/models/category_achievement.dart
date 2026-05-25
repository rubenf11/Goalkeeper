enum AchievementTier {
  bronze,
  silver,
  gold,
  green,
}

class CategoryAchievement {
  const CategoryAchievement({
    required this.categoryName,
    required this.habitCount,
    required this.completedCount,
    required this.points,
    required this.progress,
    required this.tier,
  });

  final String categoryName;
  final int habitCount;
  final int completedCount;
  final int points;
  final double progress;
  final AchievementTier tier;
}

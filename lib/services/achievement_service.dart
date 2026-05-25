import '../data/models/category_achievement.dart';
import '../data/models/habit.dart';
import '../data/repositories/achievement_repository.dart';

class AchievementService {
  final AchievementRepository _repository = AchievementRepository();

  Stream<List<CategoryAchievement>> watchCategoryAchievements() {
    return _repository.watchCurrentUserHabits().map(_buildCategoryAchievements);
  }

  List<CategoryAchievement> _buildCategoryAchievements(List<Habit> habits) {
    final Map<String, List<Habit>> habitsByCategory = <String, List<Habit>>{};
    for (final Habit habit in habits) {
      habitsByCategory.putIfAbsent(habit.category, () => <Habit>[]).add(habit);
    }

    final List<CategoryAchievement> achievements = habitsByCategory.entries.map((entry) {
      final List<Habit> categoryHabits = entry.value;
      final int points = _pointsForCategory(categoryHabits);
      final AchievementTier tier = _tierForPoints(points);

      return CategoryAchievement(
        categoryName: entry.key,
        habitCount: categoryHabits.length,
        completedCount: categoryHabits.where((habit) => habit.isDone).length,
        points: points,
        progress: _progressFor(points, tier),
        tier: tier,
      );
    }).toList()
      ..sort((a, b) {
        final int pointsComparison = b.points.compareTo(a.points);
        if (pointsComparison != 0) {
          return pointsComparison;
        }
        return a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
      });

    return achievements;
  }

  int _pointsForCategory(List<Habit> habits) {
    return habits.fold<int>(
      0,
      (sum, habit) => sum + (habit.daysCompleted * _pointsPerCompletion(habit.frequency)),
    );
  }

  int _pointsPerCompletion(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 1;
      case Frequency.weekly:
        return 7;
      case Frequency.monthly:
        return 30;
      case Frequency.yearly:
        return 360;
    }
  }

  AchievementTier _tierForPoints(int points) {
    if (points >= 100) {
      return AchievementTier.green;
    }
    if (points >= 50) {
      return AchievementTier.gold;
    }
    if (points >= 25) {
      return AchievementTier.silver;
    }
    return AchievementTier.bronze;
  }

  double _progressFor(int points, AchievementTier tier) {
    if (tier == AchievementTier.green) {
      return 1;
    }

    late final int minPoints;
    late final int maxPoints;

    switch (tier) {
      case AchievementTier.bronze:
        minPoints = 0;
        maxPoints = 25;
        break;
      case AchievementTier.silver:
        minPoints = 25;
        maxPoints = 50;
        break;
      case AchievementTier.gold:
        minPoints = 50;
        maxPoints = 100;
        break;
      case AchievementTier.green:
        minPoints = 100;
        maxPoints = 100;
        break;
    }

    return ((points - minPoints) / (maxPoints - minPoints)).clamp(0.0, 1.0);
  }
}

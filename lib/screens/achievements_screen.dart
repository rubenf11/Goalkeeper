import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/habit.dart';
import '../widgets/habit_category_catalog.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const Color _primaryColor = Color(0xFF006B59);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textColorDark = Color(0xFF1E293B);
  static const Color _textColorLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final HabitService habitService = context.read<HabitService>();
    final User? currentUser = AuthService().currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in to view your achievements.'))
          : StreamBuilder<List<Habit>>(
              stream: habitService.watchCurrentUserHabits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Habit> habits = snapshot.data ?? const <Habit>[];
                final Map<String, List<Habit>> habitsByCategory = {};
                for (final Habit habit in habits) {
                  habitsByCategory.putIfAbsent(habit.category, () => <Habit>[]).add(habit);
                }

                final List<_CategoryMedal> categoryMedals = habitsByCategory.entries.map((entry) {
                  final HabitCategoryOption categoryOption = HabitCategoryCatalog.optionFor(entry.key);
                  final List<Habit> categoryHabits = entry.value;
                  final int completedCount = categoryHabits.where((habit) => habit.isDone).length;
                  final int points = _pointsForCategory(categoryHabits);
                  final _MedalTier medalTier = _medalTierForPoints(points);

                  return _CategoryMedal(
                    categoryName: entry.key,
                    icon: categoryOption.icon,
                    habitCount: categoryHabits.length,
                    completedCount: completedCount,
                    points: points,
                    medalTier: medalTier,
                  );
                }).toList()
                  ..sort((a, b) {
                    final int pointsComparison = b.points.compareTo(a.points);
                    if (pointsComparison != 0) {
                      return pointsComparison;
                    }

                    return a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
                  });

                return SingleChildScrollView(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Text(
                        'Category Medals',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: _textColorDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (categoryMedals.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'Add a habit to unlock your first category medal.',
                            style: TextStyle(
                              color: _textColorLight,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.all(2),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryMedals.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(1.5),
                              child: _CategoryMedalCard(medal: categoryMedals[index]),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'Keep adding habits and completing entries to grow each category medal. The more each category is completed, the richer the medal color becomes.',
                          style: TextStyle(
                            color: _textColorLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CategoryMedal {
  const _CategoryMedal({
    required this.categoryName,
    required this.icon,
    required this.habitCount,
    required this.completedCount,
    required this.points,
    required this.medalTier,
  });

  final String categoryName;
  final IconData icon;
  final int habitCount;
  final int completedCount;
  final int points;
  final _MedalTier medalTier;
}

class _MedalTier {
  const _MedalTier({
    required this.name,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.minPoints,
    required this.maxPoints,
  });

  final String name;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final int minPoints;
  final int maxPoints;
}

int _pointsForCategory(List<Habit> habits) {
  return habits.fold<int>(0, (sum, habit) => sum + (habit.daysCompleted * _pointsPerCompletion(habit.frequency)));
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

_MedalTier _medalTierForPoints(int points) {
  if (points >= 100) {
    return const _MedalTier(
      name: 'Green',
      color: Color(0xFF2F9E44),
      textColor: Colors.white,
      borderColor: Color(0xFF23703A),
      minPoints: 100,
      maxPoints: 100,
    );
  }

  if (points >= 50) {
    return const _MedalTier(
      name: 'Gold',
      color: Color(0xFFD4AF37),
      textColor: Color(0xFF3A2B00),
      borderColor: Color(0xFFB38E19),
      minPoints: 50,
      maxPoints: 100,
    );
  }

  if (points >= 25) {
    return const _MedalTier(
      name: 'Silver',
      color: Color(0xFFC0C0C0),
      textColor: Color(0xFF334155),
      borderColor: Color(0xFF8A8A8A),
      minPoints: 25,
      maxPoints: 50,
    );
  }

  return const _MedalTier(
    name: 'Bronze',
    color: Color(0xFFCD7F32),
    textColor: Colors.white,
    borderColor: Color(0xFF9A5E22),
    minPoints: 0,
    maxPoints: 25,
  );
}

class _CategoryMedalCard extends StatelessWidget {
  const _CategoryMedalCard({required this.medal});

  final _CategoryMedal medal;

  double _categoryFontSize(String categoryName) {
    final int length = categoryName.trim().length;
    if (length >= 26) {
      return 13;
    }
    if (length >= 20) {
      return 14;
    }
    if (length >= 15) {
      return 16;
    }
    if (length >= 11) {
      return 18;
    }
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    const double progressElementHeight = 12;

    final double progress = medal.medalTier.maxPoints == medal.medalTier.minPoints
        ? 1.0
        : ((medal.points - medal.medalTier.minPoints) /
                (medal.medalTier.maxPoints - medal.medalTier.minPoints))
            .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: medal.medalTier.borderColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: medal.medalTier.color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            medal.categoryName,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _categoryFontSize(medal.categoryName),
              fontWeight: FontWeight.w700,
              color: AchievementsScreen._textColorDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  medal.medalTier.color.withValues(alpha: 0.95),
                  medal.medalTier.color,
                ],
                stops: const [0.2, 1.0],
              ),
              border: Border.all(
                color: medal.medalTier.borderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: medal.medalTier.color.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  medal.icon,
                  size: 36,
                  color: medal.medalTier.textColor,
                ),
                
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: progressElementHeight,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(medal.medalTier.color),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Container(
                        height: progressElementHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, -1),
                          child: Text(
                            '${medal.points} pts',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
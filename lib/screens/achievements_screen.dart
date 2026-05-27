import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/category_achievement.dart';
import '../widgets/habit_category_catalog.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const Color _primaryColor = Color(0xFF006B59);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textColorDark = Color(0xFF1E293B);
  static const Color _textColorLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final AchievementService achievementService = context
        .read<AchievementService>();
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
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Please sign in to view your achievements.'),
            )
          : StreamBuilder<List<CategoryAchievement>>(
              stream: achievementService.watchCategoryAchievements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<CategoryAchievement> categoryMedals =
                    snapshot.data ?? const <CategoryAchievement>[];

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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(1.5),
                              child: _CategoryMedalCard(
                                medal: categoryMedals[index],
                              ),
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
                          style: TextStyle(color: _textColorLight, height: 1.4),
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

class _MedalVisualStyle {
  const _MedalVisualStyle({
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  final Color color;
  final Color textColor;
  final Color borderColor;
}

_MedalVisualStyle _visualStyleForTier(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.green:
      return const _MedalVisualStyle(
        color: Color(0xFF2F9E44),
        textColor: Colors.white,
        borderColor: Color(0xFF23703A),
      );
    case AchievementTier.gold:
      return const _MedalVisualStyle(
        color: Color(0xFFD4AF37),
        textColor: Color(0xFF3A2B00),
        borderColor: Color(0xFFB38E19),
      );
    case AchievementTier.silver:
      return const _MedalVisualStyle(
        color: Color(0xFFC0C0C0),
        textColor: Color(0xFF334155),
        borderColor: Color(0xFF8A8A8A),
      );
    case AchievementTier.bronze:
      return const _MedalVisualStyle(
        color: Color(0xFFCD7F32),
        textColor: Colors.white,
        borderColor: Color(0xFF9A5E22),
      );
  }
}

class _CategoryMedalCard extends StatelessWidget {
  const _CategoryMedalCard({required this.medal});

  final CategoryAchievement medal;

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
    final HabitCategoryOption categoryOption = HabitCategoryCatalog.optionFor(
      medal.categoryName,
    );
    final _MedalVisualStyle visualStyle = _visualStyleForTier(medal.tier);
    const double progressElementHeight = 12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: visualStyle.borderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: visualStyle.color.withValues(alpha: 0.08),
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
                  visualStyle.color.withValues(alpha: 0.95),
                  visualStyle.color,
                ],
                stops: const [0.2, 1.0],
              ),
              border: Border.all(color: visualStyle.borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: visualStyle.color.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  categoryOption.icon,
                  size: 36,
                  color: visualStyle.textColor,
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
                    value: medal.progress,
                    minHeight: progressElementHeight,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      visualStyle.color,
                    ),
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

import 'package:flutter/material.dart';

import 'habit_category_catalog.dart';

class HabitCard extends StatelessWidget {
  final String category;
  final String name;
  final int goal;
  final int progress;
  final String unit;
  final int streak;
  final bool accelerometer;
  final VoidCallback? onTap;
  final VoidCallback? onRecordTap;

  const HabitCard({
    Key? key,
    required this.category,
    required this.name,
    required this.goal,
    required this.progress,
    required this.unit,
    required this.streak,
    this.accelerometer = false,
    this.onTap,
    this.onRecordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progressPercent = goal > 0 ? progress / goal : 0;
    final categoryOption = HabitCategoryCatalog.optionFor(category);

    final Color primaryColor = const Color(0xFF006B59);
    final Color textColorDark = const Color(0xFF1E293B);
    final Color textColorLight = const Color(0xFF64748B);
    final Color progressBgColor = const Color(0xFFEEF2F6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryOption.icon, color: primaryColor, size: 24),
            ),

            const SizedBox(width: 16),

            // Name and progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColorDark,
                        ),
                      ),
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (accelerometer)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: onRecordTap,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.sensors,
                                color: Color(0xFF006B59),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent > 1 ? 1 : progressPercent,
                      backgroundColor: progressBgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$progress / $goal $unit',
                    style: TextStyle(fontSize: 12, color: textColorLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

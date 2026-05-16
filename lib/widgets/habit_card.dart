import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  final String name;
  final int goal;
  final int progress;
  final String unit;
  final VoidCallback? onTap;

  const HabitCard({
    Key? key,
    required this.name,
    required this.goal,
    required this.progress,
    required this.unit,
    this.onTap,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    double progressPercent = goal > 0 ? progress / goal : 0;

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
              color: Colors.black.withOpacity(0.02),
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
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 24),
            ),

            const SizedBox(width: 16),

            // Name and progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColorDark
                    ),
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
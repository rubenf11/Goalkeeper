import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../data/models/habit.dart';
import '../services/habit_service.dart';
import 'add_entry_screen.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_filter_sheet.dart';

class CreateEntryScreen extends StatefulWidget {
  const CreateEntryScreen({super.key});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textColorDark = const Color(0xFF1E293B);

  final HabitService _habitService = HabitService();
  final AuthService _authService = AuthService();
  HabitFilter _filter = const HabitFilter();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Add Entry',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in to add entries.'))
          : StreamBuilder<List<Habit>>(
              stream: _habitService.watchCurrentUserHabits(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final habits = snapshot.data!;
                final activeHabits = habits.where((h) => !h.isDone).toList();
                final filtered = _filter.hasActiveFilters
                    ? activeHabits.where((h) => _filter.matches(h)).toList()
                    : activeHabits;

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _filter.hasActiveFilters
                          ? 'No habits match the selected filters.'
                          : 'No active habits. Create one first.',
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: HabitFilterRow(
                        filter: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final habit = filtered[index];
                          return HabitCard(
                            category: habit.category,
                            name: habit.name,
                            goal: habit.goal,
                            progress: habit.progress,
                            unit: habit.unit,
                            streak: habit.streak,
                            accelerometer: habit.accelerometer,
                            chronometer: habit.chronometer,
                            limitGoal: habit.limitGoal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEntryScreen(
                                    habitId: habit.habitId,
                                    habitName: habit.name,
                                    habitUnit: habit.unit,
                                    currentProgress: habit.progress,
                                    chronometer: habit.chronometer,
                                  ),
                                ),
                              );
                            },
                            onRecordTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEntryScreen(
                                    habitId: habit.habitId,
                                    habitName: habit.name,
                                    habitUnit: habit.unit,
                                    currentProgress: habit.progress,
                                    chronometer: habit.chronometer,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

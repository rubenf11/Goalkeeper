import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../data/models/habit.dart';
import '../services/habit_service.dart';
import 'add_entry_screen.dart';
import '../widgets/habit_card.dart';

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

                if (activeHabits.isEmpty) {
                  return const Center(
                    child: Text('No active habits. Create one first.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeHabits.length,
                  itemBuilder: (context, index) {
                    final habit = activeHabits[index];
                    return HabitCard(
                      category: habit.category,
                      name: habit.name,
                      goal: habit.goal,
                      progress: habit.progress,
                      unit: habit.unit,
                      streak: habit.streak,
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
                    );
                  },
                );
              },
            ),
    );
  }
}

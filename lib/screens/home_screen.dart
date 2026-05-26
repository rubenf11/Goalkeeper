import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:goalkeeper/screens/habit_details_screen.dart';
import '../data/models/habit.dart';
import 'package:provider/provider.dart';
import '../../widgets/habit_card.dart';
import '../services/habit_service.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final Color progressBgColor = const Color(0xFFEEF2F6);
  final Color completedCardColor = const Color(0xFF006B59);

  final AuthService _authService = AuthService();
  User? get currentUser => _authService.currentUser;
  late final Stream<List<Habit>> _activeHabitsStream;
  final UserService _userService = UserService();

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _activeHabitsStream = context
        .read<HabitService>()
        .watchCurrentUserActiveHabits();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<HabitService>().refreshAllHabits();
    });
  }

  String getFirstName() {
    String fullName = currentUser?.displayName ?? 'User';
    return fullName.split(' ')[0];
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 19) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Icon(Icons.person, color: primaryColor)
                : null,
          ),
        ),

        title: Text(
          'GoalKeeper',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),

        // Settings Button
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColorLight),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: user == null
              ? Stream.value(null)
              : _userService.watchCurrentUserProfile(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data;
            final String displayName =
                userData?['name'] as String? ?? getFirstName();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${getGreeting()}, $displayName!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColorDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Focus on progress, not perfection. Every step counts."',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: textColorLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: StreamBuilder<List<Habit>>(
                    stream: _activeHabitsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final habits = snapshot.data ?? [];
                      final activeHabits = habits
                          .where((habit) => !habit.isDone)
                          .toList();
                      final progressCards = <Widget>[
                        if (activeHabits.any(
                          (habit) => habit.frequency == Frequency.daily,
                        ))
                          _buildProgressCard(
                            title: 'Daily Progress',
                            habits: activeHabits,
                            frequency: Frequency.daily,
                            typeLabel: 'daily',
                          ),
                        if (activeHabits.any(
                          (habit) => habit.frequency == Frequency.weekly,
                        ))
                          _buildProgressCard(
                            title: 'Weekly Progress',
                            habits: activeHabits,
                            frequency: Frequency.weekly,
                            typeLabel: 'weekly',
                          ),
                        if (activeHabits.any(
                          (habit) => habit.frequency == Frequency.monthly,
                        ))
                          _buildProgressCard(
                            title: 'Monthly Progress',
                            habits: activeHabits,
                            frequency: Frequency.monthly,
                            typeLabel: 'monthly',
                          ),
                        if (activeHabits.any(
                          (habit) => habit.frequency == Frequency.yearly,
                        ))
                          _buildProgressCard(
                            title: 'Yearly Progress',
                            habits: activeHabits,
                            frequency: Frequency.yearly,
                            typeLabel: 'yearly',
                          ),
                      ];

                      if (progressCards.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'No active habits yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColorLight,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _pageController,
                          children: progressCards,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE HABITS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColorLight,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentUser == null)
                  Text(
                    'Sign in to see your habits.',
                    style: TextStyle(color: textColorLight),
                  )
                else
                  StreamBuilder<List<Habit>>(
                    stream: _activeHabitsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error while loading data');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final habits = snapshot.data ?? const <Habit>[];

                      if (habits.isEmpty) {
                        return Text(
                          'No habits created yet.',
                          style: TextStyle(color: textColorLight),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];

                          return HabitCard(
                            category: habit.category,
                            name: habit.name,
                            goal: habit.goal,
                            progress: habit.progress,
                            unit: habit.unit,
                            streak: habit.streak,
                            accelerometer: habit.accelerometer,
                            onTap: () => _navigateToDetails(habit),
                            onRecordTap: () => _navigateToDetails(habit),
                          );
                        },
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetails(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsScreen(
          habitId: habit.id,
          name: habit.name,
          goal: habit.goal,
          progress: habit.progress,
          unit: habit.unit,
          streak: habit.streak,
          created_at: Timestamp.fromDate(habit.createdAt ?? DateTime.now()),
          frequency: habit.frequency,
          accelerometer: habit.accelerometer,
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required List<Habit> habits,
    required Frequency frequency,
    required String typeLabel,
  }) {
    final filteredHabits = habits
        .where((h) => h.frequency == frequency)
        .toList();
    final int total = filteredHabits.length;
    final int completed = filteredHabits.where((h) => h.goalReached).length;
    final double percentage = total > 0 ? completed / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColorDark,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 12,
                  backgroundColor: progressBgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              Text(
                "${(percentage * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColorDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            total > 0
                ? "$completed of $total $typeLabel habits completed"
                : "No $typeLabel habits created.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColorLight,
            ),
          ),
        ],
      ),
    );
  }
}

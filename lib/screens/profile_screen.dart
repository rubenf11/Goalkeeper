import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/habit.dart';
import '../data/models/moment_photo.dart';
import 'home_screen.dart';
import 'habit_details_screen.dart';
import '../services/moment_service.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final Color accentGreen = const Color(0xFF10B981);
  final MomentService _momentService = MomentService();
  final HabitService _habitService = HabitService();


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data ?? FirebaseAuth.instance.currentUser;

        if (authSnapshot.connectionState == ConnectionState.waiting && currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUser == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: Text('Please sign in to view your profile.')),
          );
        }

        return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'GoalKeeper',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            }, 
            icon: Icon(Icons.logout_outlined, color: Colors.red,)
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Photo
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: currentUser.photoURL != null 
                        ? NetworkImage(currentUser.photoURL!) 
                        : null,
                      child: currentUser.photoURL == null 
                        ? Icon(Icons.person, size: 60, color: primaryColor) 
                        : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // User name section
            Text(
              currentUser.displayName ?? '??????',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColorDark),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark),),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<MomentPhoto>>(
              stream: _momentService.watchMomentsForUser(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }

                final photos = snapshot.data ?? const <MomentPhoto>[];

                if (photos.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'No photos yet',
                      style: TextStyle(color: textColorLight),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const ColoredBox(
                            color: Color(0xFFE2E8F0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: Color(0xFFE2E8F0),
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('My Habits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark)),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<Habit>>(
              stream: _habitService.watchCurrentUserHabits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }

                final habits = snapshot.data ?? const <Habit>[];

                // Sort by days completed descending so most active habits appear first
                habits.sort((a, b) => (b.daysCompleted).compareTo(a.daysCompleted));

                if (habits.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'No habits yet',
                      style: TextStyle(color: textColorLight),
                    ),
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
                      onTap: () {
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
                              created_at: Timestamp.fromDate(
                                habit.createdAt ?? DateTime.now(),
                              ),
                              frequency: habit.frequency,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            
          ],
        ),
      ),
    );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

  final User? currentUser = FirebaseAuth.instance.currentUser;

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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.2),
            child: Icon(Icons.person, color: primaryColor),
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
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getGreeting()}, ${getFirstName()}!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColorDark),
            ),
            const SizedBox(height: 8),
            Text(
              '"Focus on progress, not perfection. Every step counts."',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textColorLight),
            ),
            const SizedBox(height: 32),

            // Daily progress container
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [  
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 12,
                            backgroundColor: progressBgColor,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('75%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                                Text("TODAY'S GOAL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColorLight, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('Daily Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark)),
                    const SizedBox(height: 4),
                    Text('3 of 4 habits completed', style: TextStyle(color: textColorLight)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE HABITS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColorLight, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),

    );
  }

}
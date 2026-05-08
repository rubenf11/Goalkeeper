import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  final User? currentUser = FirebaseAuth.instance.currentUser;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
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
                alignment: Alignment.bottomRight,
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
                      backgroundImage: currentUser?.photoURL != null 
                        ? NetworkImage(currentUser!.photoURL!) 
                        : null,
                      child: currentUser?.photoURL == null 
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
              currentUser?.displayName ?? '??????',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColorDark),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark),),
                Text('View all', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                ],
              ),
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('My Habits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark)),
            ),
            
          ],
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/models/habit.dart';
import '../data/models/moment_photo.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../services/moment_service.dart';
import '../services/user_service.dart';
import '../widgets/habit_card.dart';
import 'gallery_screen.dart';
import 'habit_details_screen.dart';
import '../services/entry_service.dart';
import '../services/accelerometer_tracking_service.dart';
import '../services/chronometer_tracking_service.dart';
import '../widgets/moment_details_dialog.dart';

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
  final AuthService _authService = AuthService();
  final MomentService _momentService = MomentService();
  final HabitService _habitService = HabitService();
  final UserService _userService = UserService();
  final AccelerometerTrackingService _trackingService =
      AccelerometerTrackingService();
  final ChronometerTrackingService _chronoTrackingService =
      ChronometerTrackingService();
  bool _isUploadingPhoto = false;
  Set<String> _recordingHabitIds = {};

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_isUploadingPhoto) {
      return;
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF006B59),
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF006B59)),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      await _authService.updateProfilePhoto(File(pickedImage.path));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar({required String? photoUrl}) {
    return Center(
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
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, size: 60, color: primaryColor)
                  : null,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              color: primaryColor,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: _isUploadingPhoto ? null : _pickAndUploadProfilePhoto,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(String userId) {
    return StreamBuilder<List<MomentPhoto>>(
      stream: _momentService.watchMomentsForUser(userId),
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

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final entryService = context.read<EntryService>();

                    final habitService = context.read<HabitService>();

                    final entry = await entryService.getEntryByImageUrl(
                      photo.habitId,
                      photo.imageUrl,
                    );

                    final habit = await habitService
                        .watchHabit(photo.habitId)
                        .first;

                    if (context.mounted) Navigator.pop(context);

                    if (entry != null && habit != null && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => MomentDetailDialog(
                          photo: photo,
                          entry: entry,
                          habitName: habit.name,
                          unit: habit.unit,
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
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
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            );
                          },
                        ),
                        if (photo.caption != null && photo.caption!.isNotEmpty)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.65),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Text(
                                photo.caption!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _recordingHabitIds = {
      ..._trackingService.allData.value.keys,
      ..._chronoTrackingService.allData.value.keys,
    };
    _trackingService.allData.addListener(_onRecordingChanged);
    _chronoTrackingService.allData.addListener(_onRecordingChanged);
  }

  @override
  void dispose() {
    _trackingService.allData.removeListener(_onRecordingChanged);
    _chronoTrackingService.allData.removeListener(_onRecordingChanged);
    super.dispose();
  }

  void _onRecordingChanged() {
    final newIds = {
      ..._trackingService.allData.value.keys,
      ..._chronoTrackingService.allData.value.keys,
    };
    if (newIds.length == _recordingHabitIds.length &&
        _recordingHabitIds.containsAll(newIds))
      return;
    setState(() {
      _recordingHabitIds = newIds;
    });
  }

  Widget _buildHabitList() {
    return StreamBuilder<List<Habit>>(
      stream: _habitService.watchCurrentUserHabits(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          );
        }

        final habits = snapshot.data ?? const <Habit>[];
        habits.sort((a, b) => b.daysCompleted.compareTo(a.daysCompleted));

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
              accelerometer: habit.accelerometer,
              chronometer: habit.chronometer,
              limitGoal: habit.limitGoal,
              isRecording: _recordingHabitIds.contains(habit.id),
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
                      accelerometer: habit.accelerometer,
                      chronometer: habit.chronometer,
                      limitGoal: habit.limitGoal,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data ?? _authService.currentUser;

        if (authSnapshot.connectionState == ConnectionState.waiting &&
            currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUser == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(
              child: Text('Please sign in to view your profile.'),
            ),
          );
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _userService.watchCurrentUserProfile(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data;
            final String? photoUrl =
                userData?['photoUrl'] as String? ?? currentUser.photoURL;
            final String displayName =
                userData?['name'] as String? ??
                currentUser.displayName ??
                '??????';

            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: backgroundColor,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'GoalKeeper',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    icon: const Icon(Icons.logout_outlined, color: Colors.red),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileAvatar(photoUrl: photoUrl),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColorDark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColorDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GalleryScreen(userId: currentUser.uid),
                              ),
                            );
                          },
                          child: Text(
                            'Show all',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGallery(currentUser.uid),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Habits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColorDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHabitList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

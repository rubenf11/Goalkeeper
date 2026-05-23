import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/moment_photo.dart';
import 'add_entry_screen.dart';
import '../services/habit_service.dart';
import '../services/moment_service.dart';

class HabitDetailsScreen extends StatefulWidget {
  final String habitId;
  final String name;
  final int goal;
  final int progress;
  final String unit;
  final int streak;
  final Timestamp created_at;

  const HabitDetailsScreen({
    super.key,
    required this.habitId,
    required this.name,
    required this.goal,
    required this.progress,
    required this.unit,
    required this.streak,
    required this.created_at,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreen();
}

class _HabitDetailsScreen extends State<HabitDetailsScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final HabitService _habitService = HabitService();
  final MomentService _momentService = MomentService();

  late final Stream<Map<String, num>> _chartStream;

  @override
  void initState() {
    super.initState();
    _chartStream = _habitService.watchDailyProgress(widget.habitId);

    // Recalculate stats once when opening the habit details page to ensure
    // displayed metrics are up-to-date (handles cases where entries were added elsewhere).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _habitService.recalculateHabitStats(widget.habitId).catchError((e, st) {
        print('recalculateHabitStats (onOpen) ERROR for ${widget.habitId}: $e');
        print(st);
      });
    });
  }

  Future<void> _showConfirmationDialog(bool isCurrentlyDone) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
          ),
          title: Text(
            isCurrentlyDone ? "Continue Habit" : "Mark as Completed",
            style: TextStyle(color: textColorDark, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isCurrentlyDone
                ? "Are you sure you want to continue this habit?"
                : "Are you sure you want to mark this habit as completed?",
            style: TextStyle(color: textColorLight),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(color: textColorLight, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(8)
                ),
              ),
              child: Text(
                isCurrentlyDone ? "Continue" : "Confirm",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final error = await _habitService.setHabitCompletionStatus(
                  habitId: widget.habitId,
                  isDone: !isCurrentlyDone,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Habit marked as completed!'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes for this specific habit to keep UI updated
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('habits').doc(widget.habitId).snapshots(),
      builder: (context, snapshot) {
        int currentProgress = widget.progress;
        int currentStreak = widget.streak;
        int currentHighestStreak = 0;
        int currentDaysCompleted = 0;
        bool isDone = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          currentProgress = (data['progress'] as num?)?.toInt() ?? 0;
          currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
          currentHighestStreak = (data['highest_streak'] as num?)?.toInt() ?? 0;
          currentDaysCompleted = (data['days_completed'] as num?)?.toInt() ?? 0;
          isDone = data['is_done'] as bool? ?? false;
        }

        double progressPercentage = widget.goal > 0 ? currentProgress / widget.goal : 0;
        if (progressPercentage > 1.0) progressPercentage = 1.0;
        
        DateTime date = widget.created_at.toDate();
        String habitDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColorDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.name,
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: textColorDark),
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (String choice) {
                  if (choice == 'add_entry') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEntryScreen(
                          habitId: widget.habitId,
                          habitName: widget.name,
                          habitUnit: widget.unit,
                          currentProgress: widget.progress,
                        ),
                      ),
                    );
                  }
                  else if (choice == 'mark_completed') {
                    _showConfirmationDialog(isDone);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_entry',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                        SizedBox(width: 12),
                        Text("Add Entry"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mark_completed',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                        const SizedBox(width: 12),
                        Text(isDone ? 'Continue Habit' : 'Mark as completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildCircularProgress(currentProgress, progressPercentage),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("STREAK", '$currentStreak days')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard("Created at", habitDate)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("HIGHEST STREAK", '$currentHighestStreak days')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard("DAYS COMPLETED", '$currentDaysCompleted')),
                  ],
                ),
                const SizedBox(height: 24),
                _buildChartSection(),

                const SizedBox(height: 24),
                _buildDailyMomentsSection(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildCircularProgress(int progress, double percentage) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 20,
              backgroundColor: primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$progress', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColorDark)),
              Text("/ ${widget.goal} ${widget.unit}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColorLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, {bool large = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColorLight, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: large ? 20 : 17, fontWeight: FontWeight.bold, color: textColorDark)),
        ],
      ),
    );
  }

  Widget _buildDailyMomentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Captured Moments", style: TextStyle(fontWeight: FontWeight.bold, color: textColorDark, fontSize: 16)),
            Text("View Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<MomentPhoto>>(
          stream: _momentService.watchHabitMoments(widget.habitId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final photos = snapshot.data ?? const <MomentPhoto>[];

            if (photos.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    "No moments captured yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ClipRRect(
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
                            child: Center(child: Icon(Icons.broken_image_outlined)),
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Activity Overview",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: textColorDark, 
            fontSize: 16
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4), 
              ),
            ],
          ),
          child: StreamBuilder<Map<String,num>>(
            stream: _chartStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error while loading stats data", 
                    style: TextStyle(color: textColorLight)
                  )
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final progressMap = snapshot.data ?? {};

              final DateTime now = DateTime.now();
              final List<DateTime> last7Days = List.generate(
                7, 
                (index) => now.subtract(Duration(days: 6 - index)),
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: last7Days.map((date) {
                  String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                  num progress = progressMap[dateStr] ?? 0;
                  double percentage = widget.goal > 0.0 ? (progress / widget.goal) : 0.0;
                  if (percentage > 1) percentage = 1;

                  final List<String> weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  String dayLabel = weekdays[date.weekday];

                  bool isToday = date.day == now.day && 
                                 date.month == now.month && 
                                 date.year == now.year;
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progress.toInt().toString(),
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? primaryColor : textColorLight
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        width: 14,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          height: 120 * percentage,
                          decoration: BoxDecoration(
                            color: percentage >= 1.0 ? Colors.blue : Colors.red.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? primaryColor : textColorDark,
                        ),
                      ),
                    ],
                  );
                }).toList(),    
              );
            },
          ),
        ),
      ],
    );
  }
}

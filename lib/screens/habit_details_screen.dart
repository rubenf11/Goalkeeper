import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/moment_photo.dart';
import '../data/models/habit.dart';
import '../data/models/accelerometer_tracking_data.dart';
import 'package:provider/provider.dart';
import 'add_entry_screen.dart';
import '../services/habit_service.dart';
import '../services/moment_service.dart';
import '../services/accelerometer_tracking_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/moment_details_dialog.dart';
import '../widgets/accelerometer_confirmation_sheet.dart';
import '../services/entry_service.dart';

class HabitDetailsScreen extends StatefulWidget {
  final String habitId;
  final String name;
  final double goal;
  final double progress;
  final String unit;
  final int streak;
  final Timestamp created_at;
  final Frequency frequency;
  final bool accelerometer;

  const HabitDetailsScreen({
    super.key,
    required this.habitId,
    required this.name,
    required this.goal,
    required this.progress,
    required this.unit,
    required this.streak,
    required this.created_at,
    required this.frequency,
    this.accelerometer = false,
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

  String _selectedPeriod = 'Daily';
  String _selectedChartMode = 'Sum';
  late final Stream<Map<String, num>> _chartStream;

  final AccelerometerTrackingService _trackingService =
      AccelerometerTrackingService();
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _chartStream = context.read<HabitService>().watchDailyProgress(
      widget.habitId,
    );

    _trackingService.trackingData.addListener(_onTrackingDataChanged);

    // Recalculate stats once when opening the habit details page to ensure
    // displayed metrics are up-to-date (handles cases where entries were added elsewhere).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<HabitService>()
          .recalculateHabitStats(widget.habitId)
          .catchError((e, st) {
            print(
              'recalculateHabitStats (onOpen) ERROR for ${widget.habitId}: $e',
            );
            print(st);
          });
    });
  }

  @override
  void dispose() {
    _trackingService.trackingData.removeListener(_onTrackingDataChanged);
    _trackingService.dispose();
    super.dispose();
  }

  void _onTrackingDataChanged() {
    if (!mounted) return;
    setState(() {
      _isTracking = _trackingService.trackingData.value.isRecording;
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
                style: TextStyle(
                  color: textColorLight,
                  fontWeight: FontWeight.bold,
                ),
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
                  borderRadius: BorderRadiusGeometry.circular(8),
                ),
              ),
              child: Text(
                isCurrentlyDone ? "Continue" : "Confirm",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final error = await context
                    .read<HabitService>()
                    .setHabitCompletionStatus(
                      habitId: widget.habitId,
                      isDone: !isCurrentlyDone,
                    );

                if (!mounted) return;

                if (!isCurrentlyDone) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Habit marked as completed!'),
                      backgroundColor: error == null
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Habit reativated!'),
                      backgroundColor: error == null
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes for this specific habit to keep UI updated
    return StreamBuilder<Habit?>(
      stream: context.read<HabitService>().watchHabit(widget.habitId),
      builder: (context, snapshot) {
        final habitData = snapshot.data;

        double currentProgress = habitData?.progress ?? widget.progress;
        int currentStreak = habitData?.streak ?? widget.streak;
        int currentHighestStreak = habitData?.highestStreak ?? 0;
        int currentDaysCompleted = habitData?.daysCompleted ?? 0;
        String periodSingular;
        String periodPlural;
        bool isDone = habitData?.isDone ?? false;

        double progressPercentage = widget.goal > 0
            ? currentProgress / widget.goal
            : 0;
        if (progressPercentage > 1.0) progressPercentage = 1.0;

        DateTime date = widget.created_at.toDate();
        String habitDate =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

        switch (widget.frequency) {
          case Frequency.daily:
            periodSingular = 'day';
            periodPlural = 'days';
            break;
          case Frequency.weekly:
            periodSingular = 'week';
            periodPlural = 'weeks';
            break;
          case Frequency.monthly:
            periodSingular = 'month';
            periodPlural = 'months';
            break;
          case Frequency.yearly:
            periodSingular = 'year';
            periodPlural = 'years';
            break;
        }

        final streakPeriodLabel = currentStreak == 1
            ? periodSingular
            : periodPlural;
        final highestStreakPeriodLabel = currentHighestStreak == 1
            ? periodSingular
            : periodPlural;
        final completedPeriodLabel = currentDaysCompleted == 1
            ? periodSingular
            : periodPlural;
        final completedTitle =
            '${completedPeriodLabel[0].toUpperCase()}${completedPeriodLabel.substring(1)} Completed';

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: textColorDark,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.name,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
                  } else if (choice == 'mark_completed') {
                    _showConfirmationDialog(isDone);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_entry',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text("Add Entry"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mark_completed',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.black,
                          size: 20,
                        ),
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
                if (widget.accelerometer) ...[
                  const SizedBox(height: 24),
                  _buildRecordingSection(),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "STREAK",
                        '$currentStreak $streakPeriodLabel',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard("Created at", habitDate)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "HIGHEST STREAK",
                        '$currentHighestStreak $highestStreakPeriodLabel',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        completedTitle,
                        '$currentDaysCompleted',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Analytics",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColorDark,
                      ),
                    ),

                    if (_selectedPeriod != "Daily") ...[
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'Sum',
                            label: Text('Sum'),
                            icon: Icon(Icons.functions, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'Average',
                            label: Text('Average'),
                            icon: Icon(Icons.analytics, size: 16),
                          ),
                        ],
                        selected: {_selectedChartMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedChartMode = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: primaryColor,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: textColorLight,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _buildChartPeriodSelector(),
                const SizedBox(height: 24),
                _buildActiveChart(widget.habitId, _selectedChartMode),
                const SizedBox(height: 24),
                _buildDailyMomentsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    if (!await AccelerometerTrackingService.hasPermission()) {
      final granted = await AccelerometerTrackingService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Step tracking needs activity recognition permission. '
              'Please enable it in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return;
      }
    }
    if (!mounted) return;
    _trackingService.startRecording();
    setState(() {});
  }

  Future<void> _stopRecording() async {
    _trackingService.stopRecording();
    final data = _trackingService.trackingData.value;
    setState(() {});

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AccelerometerConfirmationSheet(
        data: data,
        habitName: widget.name,
        habitUnit: widget.unit,
        habitId: widget.habitId,
      ),
    );

    if (result == null || !mounted) return;

    final entryService = context.read<EntryService>();
    final error = await entryService.addEntrytoHabit(
      habitId: widget.habitId,
      amount: result['amount'] as double,
      imageFile: result['imageFile'] as File?,
      caption: result['caption'] as String?,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved from recording!'),
          backgroundColor: Colors.green,
        ),
      );
      context.read<HabitService>().recalculateHabitStats(widget.habitId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRecordingSection() {
    return ValueListenableBuilder<AccelerometerTrackingData>(
      valueListenable: _trackingService.trackingData,
      builder: (context, data, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isTracking
                ? primaryColor.withValues(alpha: 0.05)
                : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isTracking
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: _isTracking
              ? _buildActiveRecording(data)
              : _buildIdleRecording(),
        );
      },
    );
  }

  Widget _buildIdleRecording() {
    return InkWell(
      onTap: _startRecording,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sensors,
              color: Color(0xFF006B59),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-track with accelerometer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColorDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to start counting steps and distance',
                  style: TextStyle(color: textColorLight, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'Record',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecording(AccelerometerTrackingData data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recording...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.elapsedFormatted,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildRecordingStat(
                '${data.steps}',
                'Steps',
                Icons.directions_walk,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRecordingStat(
                data.distanceFormatted,
                'Distance',
                Icons.straighten,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text(
              'Stop Recording',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: textColorDark,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: textColorLight)),
        ],
      ),
    );
  }

  static String _formatNum(num value) {
    final s = (value is double ? value : value.toDouble()).toStringAsFixed(2);
    if (s.contains('.')) {
      final trimmed = s.replaceAll(RegExp(r'0*$'), '');
      return trimmed.endsWith('.')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }
    return s;
  }

  Widget _buildCircularProgress(double progress, double percentage) {
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
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatNum(progress),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColorDark,
                ),
              ),
              Text(
                "/ ${_formatNum(widget.goal)} ${widget.unit}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColorLight,
                ),
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColorLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 20 : 17,
              fontWeight: FontWeight.bold,
              color: textColorDark,
            ),
          ),
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
            Text(
              "Captured Moments",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColorDark,
                fontSize: 18,
              ),
            ),
            Text(
              "View Gallery",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<MomentPhoto>>(
          stream: context.read<MomentService>().watchHabitMoments(
            widget.habitId,
          ),
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
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];

                return GestureDetector(
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final entryService = context.read<EntryService>();

                    final entry = await entryService.getEntryByImageUrl(
                      widget.habitId,
                      photo.imageUrl,
                    );

                    if (context.mounted) Navigator.pop(context);

                    if (entry != null && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => MomentDetailDialog(
                          photo: photo,
                          entry: entry,
                          habitName: widget.name,
                          unit: widget.unit,
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
            fontSize: 16,
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: StreamBuilder<Map<String, num>>(
            stream: _chartStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error while loading stats data",
                    style: TextStyle(color: textColorLight),
                  ),
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
                  String dateStr =
                      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                  num progress = progressMap[dateStr] ?? 0;
                  double percentage = widget.goal > 0.0
                      ? (progress / widget.goal)
                      : 0.0;
                  if (percentage > 1) percentage = 1;

                  final List<String> weekdays = [
                    '',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  String dayLabel = weekdays[date.weekday];

                  bool isToday =
                      date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatNum(progress),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday ? primaryColor : textColorLight,
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
                            color: percentage >= 1.0
                                ? Colors.blue
                                : Colors.red.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
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

  Widget _buildChartPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryColor : textColorLight,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveChart(String habitId, String mode) {
    switch (_selectedPeriod) {
      case 'Weekly':
        return _buildLineChartSection(
          title: "Weekly Analytics",
          stream: context.read<HabitService>().watchWeeklyProgress(
            habitId,
            mode: mode,
          ),
          periodType: "Weekly",
          mode: _selectedChartMode,
        );
      case 'Monthly':
        return _buildLineChartSection(
          title: "Monthly Analytics",
          stream: context.read<HabitService>().watchMonthlyProgress(
            habitId,
            mode: mode,
          ),
          periodType: "Monthly",
          mode: _selectedChartMode,
        );
      case 'Daily':
      default:
        return _buildLineChartSection(
          title: "Daily Analytics",
          stream: context.read<HabitService>().watchDailyProgress(habitId),
          periodType: "Daily",
          mode: _selectedChartMode,
        );
    }
  }

  Widget _buildLineChartSection({
    required String title,
    required Stream<Map<String, num>> stream,
    required String periodType,
    required String mode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          periodType == 'Daily' ? title : '$title ($mode)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColorDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: StreamBuilder<Map<String, num>>(
            stream: stream,
            builder: (context, snapshot) {
              final progressMap = snapshot.data ?? {};
              final DateTime now = DateTime.now();

              List<String> sortedKeys = [];
              List<FlSpot> spots = [];

              if (periodType == 'Daily') {
                for (int i = 0; i < 7; i++) {
                  final date = now.subtract(Duration(days: 6 - i));
                  final dateStr =
                      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  sortedKeys.add(dateStr);
                  spots.add(
                    FlSpot(
                      i.toDouble(),
                      (progressMap[dateStr] ?? 0).toDouble(),
                    ),
                  );
                }
              } else {
                sortedKeys = progressMap.keys.toList()..sort();
                for (int i = 0; i < sortedKeys.length; i++) {
                  spots.add(
                    FlSpot(
                      i.toDouble(),
                      progressMap[sortedKeys[i]]!.toDouble(),
                    ),
                  );
                }
              }

              if (sortedKeys.isEmpty)
                return const Center(child: Text("Sem dados suficientes"));

              final double maxXD = sortedKeys.length > 1
                  ? (sortedKeys.length - 1).toDouble()
                  : 1.0;

              double highestValue = 0;
              for (var spot in spots) {
                if (spot.y > highestValue) highestValue = spot.y;
              }

              double targetMaxY = highestValue;

              if (targetMaxY == 0) targetMaxY = 10;

              double yInterval = mode == 'Average'
                  ? (targetMaxY / 4)
                  : (targetMaxY / 4).ceilToDouble();
              if (yInterval == 0) yInterval = 1;

              return LineChart(
                LineChartData(
                  minY: 0,
                  minX: 0,
                  maxY: targetMaxY + (targetMaxY * 0.1),
                  maxX: maxXD,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => primaryColor,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (s) => LineTooltipItem(
                              mode == 'Average'
                                  ? '${s.y.toStringAsFixed(1)}'
                                  : '${s.y.toInt()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: backgroundColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value == targetMaxY + (targetMaxY * 0.1) ||
                              (mode != 'Average' && value % 1 != 0)) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _formatNum(value),
                              style: TextStyle(
                                color: textColorLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox();
                          final index = value.toInt();
                          if (index < 0 || index >= sortedKeys.length)
                            return const SizedBox();

                          String label = sortedKeys[index];
                          bool isToday = false;
                          try {
                            if (periodType == 'Monthly') {
                              final parts = label.split('-');
                              final month = int.parse(parts[1]);
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ];
                              label = months[month - 1];
                            } else if (periodType == 'Weekly') {
                              final parts = label.split('-');
                              final startDate = DateTime(
                                int.parse(parts[0]),
                                int.parse(parts[1]),
                                int.parse(parts[2]),
                              );
                              final endDate = startDate.add(
                                const Duration(days: 6),
                              );
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                              ];
                              label = startDate.month == endDate.month
                                  ? "${startDate.day}-${endDate.day} ${months[startDate.month - 1]}"
                                  : "${startDate.day} ${months[startDate.month - 1]}-${endDate.day} ${months[endDate.month - 1]}";
                            } else {
                              final parts = label.split('-');
                              final date = DateTime(
                                int.parse(parts[0]),
                                int.parse(parts[1]),
                                int.parse(parts[2]),
                              );
                              const weekdays = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              label = weekdays[date.weekday - 1];
                              isToday =
                                  date.day == now.day &&
                                  date.month == now.month;
                            }
                          } catch (e) {}
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isToday ? primaryColor : textColorLight,
                                fontSize: periodType == 'Week' ? 9 : 11,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 1,
                      color: primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: primaryColor,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.3),
                            primaryColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

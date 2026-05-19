import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goalkeeper/widgets/image_source_bottom_sheet.dart';
import '../services/image_picker_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'add_entry_screen.dart';

class HabitDetailsScreen extends StatefulWidget {
  final String habitId;
  final String name;
  final int goal;
  final int progress;
  final String unit;
  final int streak;
  final Timestamp created_at;

  const HabitDetailsScreen({
    Key? key,
    required this.habitId,
    required this.name,
    required this.goal,
    required this.progress,
    required this.unit,
    required this.streak,
    required this.created_at,
  }) : super(key: key);

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreen();
}

class _HabitDetailsScreen extends State<HabitDetailsScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final Color darkStreakColor = const Color(0xFF043227);

  final ImagePickerHelper _imageHelper = ImagePickerHelper();

  Future<void> _handleImageSelection(ImageSource source) async {
    Navigator.of(context).pop();

    final File? image = await _imageHelper.pickImage(source);
    File? _selectedImage;

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo selected with success."))
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ImageSourceBottomSheet(
          onSourceSelected: _handleImageSelection,
        );
      }
    );
  }

  Future<void> _showConfirmationDialog() async {
    bool _isDone = false;

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
            "Mark as Completed",
            style: TextStyle(color: textColorDark, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to mark this habit as completed?",
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
                "Confirm",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _isDone = true;
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit marked as completed!')),
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

    double progressPercentage = widget.goal > 0 ? widget.progress / widget.goal : 0;
    if (progressPercentage > 1.0) progressPercentage = 1.0;
    DateTime date = widget.created_at.toDate();
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString().padLeft(2, '0');
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    String habitDate = '$day/$month/$year - $hour:$minute';

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
          textAlign: TextAlign.center,
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
                _showConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'add_entry',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                    SizedBox(width: 12),
                    Text("Add Entry"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'mark_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                    SizedBox(width: 12),
                    Text("Mark as completed"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            _buildCircularProgress(progressPercentage),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(child: _buildStatCard("STREAK", widget.streak.toString() + ' days')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Created at", habitDate)),
              ],
            ),
            const SizedBox(height: 24),

            _buildDailyMomentsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double percentage) {
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
              Text(
                widget.progress.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColorDark,
                  letterSpacing: -1,
                ),
              ),

              Text(
                "/ ${widget.goal} ${widget.unit}",
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

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColorLight, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColorDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMomentsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Captured Moments", style: TextStyle(fontWeight: FontWeight.bold, color: textColorDark, fontSize: 16)),
            Text("View Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMomentImage(String url) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
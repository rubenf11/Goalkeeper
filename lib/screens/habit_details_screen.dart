import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goalkeeper/widgets/image_source_bottom_sheet.dart';
import '../data/repositories/habit_repository.dart';
import '../services/image_picker_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  
  final HabitRepository _habitRepository = HabitRepository();
  final ImagePickerHelper _imageHelper = ImagePickerHelper();

  void _showAddEntryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Entry for ${widget.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Amount',
            suffixText: widget.unit,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              int? amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await _habitRepository.addEntry(widget.habitId, amount);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry added successfully!')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    Navigator.of(context).pop();
    final File? image = await _imageHelper.pickImage(source);
    if (image != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo selected with success."))
      );
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

  @override
  Widget build(BuildContext context) {
    // Listen to changes for this specific habit to keep UI updated
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('habits').doc(widget.habitId).snapshots(),
      builder: (context, snapshot) {
        int currentProgress = widget.progress;
        int currentStreak = widget.streak;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          currentProgress = (data['progress'] as num?)?.toInt() ?? 0;
          currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
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
                onSelected: (String choice) {
                  if (choice == 'add_entry') _showAddEntryDialog();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'add_entry', child: Text("Add Entry")),
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
                const SizedBox(height: 24),
                _buildDailyMomentsSection(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton.icon(
                onPressed: _showImageSourceOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                label: const Text("Capture Moment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
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

  Widget _buildStatCard(String title, String value) {
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
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColorDark)),
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
        const SizedBox(height: 100, child: Center(child: Text("No moments captured today", style: TextStyle(color: Colors.grey)))),
      ],
    );
  }
}

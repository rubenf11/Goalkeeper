import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateEntryScreen extends StatefulWidget {
  const CreateEntryScreen({super.key});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);

  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _progressController = TextEditingController();
  String? _selectedHabitId;
  int _currentProgress = 0;
  String _unit = '';

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _updateProgress() async {
    if (_selectedHabitId == null || _progressController.text.isEmpty) return;

    int increment = int.tryParse(_progressController.text) ?? 0;
    if (increment <= 0) return;

    try {
      await FirebaseFirestore.instance
          .collection('habits')
          .doc(_selectedHabitId)
          .update({
        'progress': FieldValue.increment(increment),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated successfully!')),
        );
        setState(() {
          _progressController.clear();
          _selectedHabitId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating progress: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Habit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColorDark,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              // Ideally habits should be filtered by userId
              stream: FirebaseFirestore.instance.collection('habits').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var habits = snapshot.data!.docs;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Choose a habit'),
                      value: _selectedHabitId,
                      items: habits.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['name'] ?? 'No Name'),
                          onTap: () {
                            _currentProgress = data['progress'] ?? 0;
                            _unit = data['unit'] ?? '';
                          },
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedHabitId = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            if (_selectedHabitId != null) ...[
              Text(
                'Add Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColorDark,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _progressController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount',
                  suffixText: _unit,
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProgress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedCornerShape(30),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RoundedCornerShape extends OutlinedBorder {
  final double radius;
  const RoundedCornerShape(this.radius);

  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

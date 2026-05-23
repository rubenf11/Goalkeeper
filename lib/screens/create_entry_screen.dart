import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/models/habit.dart';
import '../services/entry_service.dart';
import '../services/habit_service.dart';

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

  final HabitService _habitService = HabitService();
  final EntryService _entryService = EntryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _progressController = TextEditingController();
  
  String? _selectedHabitId;
  String _unit = '';

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _updateProgress() async {
    if (_selectedHabitId == null || _progressController.text.isEmpty || currentUser == null) return;

    final int increment = int.tryParse(_progressController.text) ?? 0;
    if (increment <= 0) return;

    try {
      final error = await _entryService.addEntrytoHabit(
        habitId: _selectedHabitId!,
        amount: increment.toDouble(),
      );

      if (error != null) {
        throw Exception(error);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully!')),
        );
        setState(() {
          _progressController.clear();
          _selectedHabitId = null;
          _unit = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
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
      body: currentUser == null
          ? const Center(child: Text('Please sign in to add entries.'))
          : SingleChildScrollView(
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
                  StreamBuilder<List<Habit>>(
                    stream: _habitService.watchCurrentUserHabits(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final habits = snapshot.data!;

                      if (habits.isEmpty) {
                        return const Text('No habits found. Create one first!');
                      }

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
                            items: habits.map((habit) {
                              return DropdownMenuItem<String>(
                                value: habit.habitId,
                                child: Text(habit.name),
                                onTap: () {
                                  _unit = habit.unit;
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
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

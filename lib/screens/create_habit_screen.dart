import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/habit.dart';
import 'habit_details_screen.dart';
import '../services/habit_service.dart';
import '../widgets/habit_category_catalog.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({Key? key}) : super(key: key);

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final HabitService _habitService = HabitService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  final Color _primaryColor = const Color(0xFF006B59);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _textColorDark = const Color(0xFF1E293B);
  final Color _textColorLight = const Color(0xFF64748B);
  final List<HabitCategoryOption> _categories = HabitCategoryCatalog.options;

  final List<String> _accelerometerUnits = ['steps', 'meters', 'km', 'miles'];
  final List<String> _trackingOptions = ['Manual', 'Step Counter'];

  String _selectedCategory = 'Health & Fitness';
  Frequency _selectedFrequency = Frequency.daily;
  bool _accelerometerEnabled = false;
  String _selectedAccelUnit = 'steps';
  String _selectedTracking = 'Manual';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _nameController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final double goal = double.parse(_goalController.text.replaceAll(',', ''));
    final double roundedGoal = double.parse(goal.toStringAsFixed(2));

    final HabitCreationResult result = await _habitService.createHabit(
      name: _nameController.text,
      category: _selectedCategory,
      frequency: _selectedFrequency,
      goal: roundedGoal,
      unit: _unitController.text,
      accelerometer: _accelerometerEnabled,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final Habit createdHabit = result.habit!;

    _formKey.currentState?.reset();
    _nameController.clear();
    _goalController.clear();
    _unitController.clear();

    setState(() {
      _selectedCategory = _categories.first.name;
      _selectedFrequency = Frequency.daily;
      _accelerometerEnabled = false;
      _selectedAccelUnit = 'steps';
      _selectedTracking = 'Manual';
    });

    final Timestamp createdAt = createdHabit.createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdHabit.createdAt!);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitDetailsScreen(
          habitId: createdHabit.id,
          name: createdHabit.name,
          goal: createdHabit.goal,
          progress: createdHabit.progress,
          unit: createdHabit.unit,
          streak: createdHabit.streak,
          created_at: createdAt,
          frequency: createdHabit.frequency,
          accelerometer: createdHabit.accelerometer,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      errorMaxLines: 3,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _primaryColor, width: 1.2),
      ),
    );
  }

  String _frequencyLabel(Frequency frequency) {
    final String value = frequency.value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _buildCategoryCard(HabitCategoryOption category) {
    final bool isSelected = category.name == _selectedCategory;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _selectedCategory = category.name;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 24,
                color: isSelected ? Colors.white : _textColorDark,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textColorDark,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'New Habit',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habit Name',
                  style: TextStyle(
                    color: _textColorDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('e.g., Morning Meditation'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a habit name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Category',
                  style: TextStyle(
                    color: _textColorDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 214,
                  child: RawScrollbar(
                    controller: _categoryScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 3,
                    radius: const Radius.circular(999),
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    thumbColor: _primaryColor.withValues(alpha: 0.75),
                    trackColor: Colors.grey.shade300,
                    trackBorderColor: Colors.transparent,
                    child: GridView.builder(
                      controller: _categoryScrollController,
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      padding: const EdgeInsets.only(bottom: 12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 168,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(_categories[index]);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Frequency',
                  style: TextStyle(
                    color: _textColorDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Frequency>(
                  value: _selectedFrequency,
                  items: Frequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(_frequencyLabel(f)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    }
                  },
                  decoration: _inputDecoration('Daily'),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking',
                            style: TextStyle(
                              color: _textColorDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedTracking,
                            items: _trackingOptions
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedTracking = value;
                                _accelerometerEnabled = value == 'Step Counter';
                                if (_accelerometerEnabled) {
                                  _unitController.text = 'steps';
                                  _selectedAccelUnit = 'steps';
                                }
                              });
                            },
                            decoration: _inputDecoration('Manual'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal Amount',
                            style: TextStyle(
                              color: _textColorDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _goalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,]'),
                              ),
                            ],
                            decoration: _inputDecoration('10'),
                            validator: (value) {
                              final String normalized = (value ?? '')
                                  .replaceAll(',', '')
                                  .trim();
                              final int? parsedGoal = int.tryParse(normalized);

                              if (parsedGoal == null || parsedGoal <= 0) {
                                return 'Enter a valid goal.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: TextStyle(
                              color: _textColorDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_accelerometerEnabled)
                            DropdownButtonFormField<String>(
                              value: _selectedAccelUnit,
                              items: _accelerometerUnits
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedAccelUnit = value;
                                    _unitController.text = value;
                                  });
                                }
                              },
                              decoration: _inputDecoration('steps'),
                            )
                          else
                            TextFormField(
                              controller: _unitController,
                              textInputAction: TextInputAction.done,
                              decoration: _inputDecoration('Times'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a unit.';
                                }
                                return null;
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primaryColor.withValues(
                        alpha: 0.55,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isSubmitting
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
                        : const Icon(Icons.add_task),
                    label: Text(
                      _isSubmitting ? 'Creating...' : 'Create Habit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

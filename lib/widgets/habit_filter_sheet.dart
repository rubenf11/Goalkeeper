import 'package:flutter/material.dart';
import 'habit_category_catalog.dart';
import '../data/models/habit.dart';

class HabitFilter {
  final String? category;
  final String? tracking;
  final Frequency? frequency;

  const HabitFilter({this.category, this.tracking, this.frequency});

  bool get hasActiveFilters =>
      category != null || tracking != null || frequency != null;

  int get activeCount =>
      (category != null ? 1 : 0) +
      (tracking != null ? 1 : 0) +
      (frequency != null ? 1 : 0);

  bool matches(Habit habit) {
    if (category != null && habit.category != category) return false;
    if (tracking != null) {
      if (tracking == 'Step Counter' && !habit.accelerometer) return false;
      if (tracking == 'Chronometer' && !habit.chronometer) return false;
      if (tracking == 'Manual' && (habit.accelerometer || habit.chronometer)) {
        return false;
      }
    }
    if (frequency != null && habit.frequency != frequency) return false;
    return true;
  }
}

class HabitFilterRow extends StatelessWidget {
  final HabitFilter filter;
  final ValueChanged<HabitFilter> onChanged;

  const HabitFilterRow({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  static const Color _primaryColor = Color(0xFF006B59);
  static const Color _textColorLight = Color(0xFF64748B);

  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _textColorLight,
  );

  static const _dropdownTextStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF1E293B),
  );
  static const _hintStyle = TextStyle(fontSize: 13, color: _textColorLight);

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      isDense: true,
    );
  }

  Widget _buildDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'Tracking',
            child: DropdownButtonFormField<String>(
              value: filter.tracking,
              decoration: _decoration(),
              isExpanded: true,
              style: _dropdownTextStyle,
              hint: const Text('All', style: _hintStyle),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('All', style: _dropdownTextStyle),
                ),
                DropdownMenuItem(
                  value: 'Manual',
                  child: Text('Manual', style: _dropdownTextStyle),
                ),
                DropdownMenuItem(
                  value: 'Step Counter',
                  child: Text('Step Counter', style: _dropdownTextStyle),
                ),
                DropdownMenuItem(
                  value: 'Chronometer',
                  child: Text('Chronometer', style: _dropdownTextStyle),
                ),
              ],
              onChanged: (v) => onChanged(
                HabitFilter(
                  category: filter.category,
                  tracking: v,
                  frequency: filter.frequency,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            label: 'Frequency',
            child: DropdownButtonFormField<Frequency>(
              value: filter.frequency,
              decoration: _decoration(),
              isExpanded: true,
              style: _dropdownTextStyle,
              hint: const Text('All', style: _hintStyle),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All', style: _dropdownTextStyle),
                ),
                ...Frequency.values.map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(
                      f.value[0].toUpperCase() + f.value.substring(1),
                      style: _dropdownTextStyle,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => onChanged(
                HabitFilter(
                  category: filter.category,
                  tracking: filter.tracking,
                  frequency: v,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            label: 'Category',
            child: DropdownButtonFormField<String>(
              value: filter.category,
              decoration: _decoration(),
              isExpanded: true,
              style: _dropdownTextStyle,
              hint: const Text('All', style: _hintStyle),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All', style: _dropdownTextStyle),
                ),
                ...HabitCategoryCatalog.options.map(
                  (c) => DropdownMenuItem(
                    value: c.name,
                    child: Text(c.name, style: _dropdownTextStyle),
                  ),
                ),
              ],
              onChanged: (v) => onChanged(
                HabitFilter(
                  category: v,
                  tracking: filter.tracking,
                  frequency: filter.frequency,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

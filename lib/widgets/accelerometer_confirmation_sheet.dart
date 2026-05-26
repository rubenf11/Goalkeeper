import 'package:flutter/material.dart';
import '../data/models/accelerometer_tracking_data.dart';

class AccelerometerConfirmationSheet extends StatefulWidget {
  final AccelerometerTrackingData data;
  final String habitName;
  final String habitUnit;
  final String habitId;

  const AccelerometerConfirmationSheet({
    super.key,
    required this.data,
    required this.habitName,
    required this.habitUnit,
    required this.habitId,
  });

  @override
  State<AccelerometerConfirmationSheet> createState() =>
      _AccelerometerConfirmationSheetState();
}

class _AccelerometerConfirmationSheetState
    extends State<AccelerometerConfirmationSheet> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final Color inputColor = const Color(0xFFEEF2F6);

  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final unit = widget.habitUnit.toLowerCase();
    _amountController = TextEditingController(
      text: _amountInUnit(unit).toStringAsFixed(unit == 'steps' ? 0 : 2),
    );
  }

  double _amountInUnit(String unit) {
    switch (unit) {
      case 'm':
      case 'meters':
        return widget.data.distanceMeters;
      case 'km':
        return widget.data.distanceMeters / 1000;
      case 'miles':
        return widget.data.distanceMeters / 1609.344;
      case 'steps':
      default:
        return widget.data.steps.toDouble();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recording Complete',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColorDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.habitName,
            style: TextStyle(color: textColorLight, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  Icons.directions_walk,
                  '${widget.data.steps}',
                  'Steps',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  Icons.timer_outlined,
                  widget.data.elapsedFormatted,
                  'Duration',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  Icons.straighten,
                  widget.data.distanceFormatted,
                  'Distance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'AMOUNT TO LOG (${widget.habitUnit})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColorLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputColor,
              suffixText: widget.habitUnit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(_amountController.text);
                if (parsed == null || parsed <= 0) return;
                Navigator.of(context).pop(parsed);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Discard', style: TextStyle(color: textColorLight)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColorDark,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: textColorLight)),
        ],
      ),
    );
  }
}

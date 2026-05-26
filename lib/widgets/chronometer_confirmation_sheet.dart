import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/chronometer_tracking_data.dart';
import 'image_source_bottom_sheet.dart';

class ChronometerConfirmationSheet extends StatefulWidget {
  final ChronometerTrackingData data;
  final String habitName;
  final String habitId;

  const ChronometerConfirmationSheet({
    super.key,
    required this.data,
    required this.habitName,
    required this.habitId,
  });

  @override
  State<ChronometerConfirmationSheet> createState() =>
      _ChronometerConfirmationSheetState();
}

class _ChronometerConfirmationSheetState
    extends State<ChronometerConfirmationSheet> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);
  final Color inputColor = const Color(0xFFEEF2F6);

  late TextEditingController _amountController;
  final TextEditingController _captionController = TextEditingController();

  File? _selectedImage;

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ImageSourceBottomSheet(
          onSourceSelected: (ImageSource source) async {
            Navigator.pop(context);
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: source,
              imageQuality: 70,
            );
            if (pickedFile != null) {
              setState(() {
                _selectedImage = File(pickedFile.path);
              });
            }
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.data.elapsedTime.inSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _captionController.dispose();
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
      child: SingleChildScrollView(
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
              'Timer Complete',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.timer_outlined, color: primaryColor, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    widget.data.elapsedFormatted,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textColorDark,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'elapsed',
                    style: TextStyle(color: textColorLight, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AMOUNT TO LOG (seconds)',
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputColor,
                suffixText: 'seconds',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ATTACH A MOMENT (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColorLight,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capture Moment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedImage = null;
                      _captionController.clear();
                    }),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      hintText: 'Write a caption for this moment...',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final parsed = double.tryParse(_amountController.text);
                  if (parsed == null || parsed <= 0) return;
                  Navigator.of(context).pop({
                    'amount': parsed,
                    'imageFile': _selectedImage,
                    'caption': _captionController.text.trim().isEmpty
                        ? null
                        : _captionController.text.trim(),
                  });
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
      ),
    );
  }
}

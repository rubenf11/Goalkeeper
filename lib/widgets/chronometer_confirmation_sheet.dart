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

  late TextEditingController _hhController;
  late TextEditingController _mmController;
  late TextEditingController _ssController;
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
    final e = widget.data.elapsedTime;
    _hhController = TextEditingController(text: e.inHours.toString());
    _mmController = TextEditingController(
      text: e.inMinutes.remainder(60).toString(),
    );
    _ssController = TextEditingController(
      text: e.inSeconds.remainder(60).toString(),
    );
  }

  @override
  void dispose() {
    _hhController.dispose();
    _mmController.dispose();
    _ssController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  int get _hh => int.tryParse(_hhController.text) ?? 0;
  int get _mm => int.tryParse(_mmController.text) ?? 0;
  int get _ss => int.tryParse(_ssController.text) ?? 0;

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
              'AMOUNT TO LOG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColorLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _hhController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'hh',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColorDark,
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: TextField(
                    controller: _mmController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration: InputDecoration(
                      hintText: 'mm',
                      counterText: '',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 59) {
                        _mmController.text = '59';
                        _mmController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _mmController.text.length),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColorDark,
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: TextField(
                    controller: _ssController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration: InputDecoration(
                      hintText: 'ss',
                      counterText: '',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 59) {
                        _ssController.text = '59';
                        _ssController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _ssController.text.length),
                        );
                      }
                    },
                  ),
                ),
              ],
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
                  final total = (_hh * 3600 + _mm * 60 + _ss).toDouble();
                  if (total <= 0) return;
                  Navigator.of(context).pop({
                    'amount': total,
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

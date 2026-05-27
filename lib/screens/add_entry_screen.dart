import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/image_source_bottom_sheet.dart';
import '../services/entry_service.dart';

class AddEntryScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  final String habitUnit;
  final double currentProgress;
  final bool chronometer;

  const AddEntryScreen({
    Key? key,
    required this.habitId,
    required this.habitName,
    required this.habitUnit,
    required this.currentProgress,
    this.chronometer = false,
  }) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color inputColor = const Color(0xFFEEF2F6);
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _hhController = TextEditingController(text: '0');
  final TextEditingController _mmController = TextEditingController(text: '0');
  final TextEditingController _ssController = TextEditingController(text: '0');
  final TextEditingController _captionController = TextEditingController();

  final EntryService _entryService = EntryService();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _valueController.dispose();
    _hhController.dispose();
    _mmController.dispose();
    _ssController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
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

  int get _hh => int.tryParse(_hhController.text) ?? 0;
  int get _mm => int.tryParse(_mmController.text) ?? 0;
  int get _ss => int.tryParse(_ssController.text) ?? 0;

  Future<void> _saveEntry() async {
    final double entryValue;
    if (widget.chronometer) {
      final total = _hh * 3600 + _mm * 60 + _ss;
      if (total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid duration')),
        );
        return;
      }
      entryValue = total.toDouble();
    } else {
      if (_valueController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a value')));
        return;
      }
      final parsed = double.tryParse(_valueController.text);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number')),
        );
        return;
      }
      if (parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry amount must be greater than zero'),
          ),
        );
        return;
      }
      entryValue = parsed;
    }

    setState(() {
      _isLoading = true;
    });

    String? errorMsg = await _entryService.addEntrytoHabit(
      habitId: widget.habitId,
      amount: entryValue,
      imageFile: _selectedImage,
      caption: _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (errorMsg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Entry to ${widget.habitName}',
          style: TextStyle(color: textColorDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColorDark),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.chronometer
                        ? 'AMOUNT TO LOG'
                        : 'PROGRESS VALUE (${widget.habitUnit.toUpperCase()})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColorLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.chronometer)
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
                                _mmController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _mmController.text.length,
                                      ),
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
                                _ssController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _ssController.text.length,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 5',
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

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
                    OutlinedButton.icon(
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
                    )
                  else
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _selectedImage = null),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Remove Photo',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 16),

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

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _saveEntry,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

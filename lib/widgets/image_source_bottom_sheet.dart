import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceBottomSheet extends StatelessWidget {
  final Color primaryColor = const Color(0xFF006B59);
  final Color textColorDark = const Color(0xFF1E293B);
  final Function(ImageSource) onSourceSelected; 

  const ImageSourceBottomSheet({
    Key? key,
    required this.onSourceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add Moment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorDark),
            ),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: primaryColor),
            title: const Text('Take Photo'),
            onTap: () {
              onSourceSelected(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: primaryColor),
            title: const Text('Choose from Gallery'),
            onTap: () {
              onSourceSelected(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/moment_photo.dart';
import '../data/models/entry.dart';

class MomentDetailDialog extends StatelessWidget {
  final MomentPhoto photo;
  final Entry entry;
  final String? habitName;
  final String? unit;

  const MomentDetailDialog({
    super.key,
    required this.photo,
    required this.entry,
    this.habitName,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF006B59);
    final Color textColorDark = const Color(0xFF1E293B);
    final Color textColorLight = const Color(0xFF64748B);

    final DateTime date = photo.timestamp ?? DateTime.now();
    final String formattedDate = DateFormat("dd MMM yyyy  HH:mm").format(date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  photo.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4)
                    ]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (habitName != null) ...[
                    Text(
                      habitName!.toUpperCase(),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: textColorLight),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(color: textColorLight, fontSize: 14),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Entry:",
                        style: TextStyle(
                          color: textColorDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "+ ${entry.amount ?? 0} ${unit ?? ''}".trim(),
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Description:",
                      style: TextStyle(
                        color: textColorDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photo.caption!,
                      style: TextStyle(
                        color: textColorDark.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
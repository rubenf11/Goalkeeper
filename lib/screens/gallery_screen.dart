import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/entry.dart';
import '../data/models/habit.dart';
import '../data/models/moment_photo.dart';
import '../services/entry_service.dart';
import '../services/habit_service.dart';
import '../services/moment_service.dart';
import '../widgets/moment_details_dialog.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final Color primaryColor = const Color(0xFF006B59);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textColorDark = const Color(0xFF1E293B);
  final Color textColorLight = const Color(0xFF64748B);

  Future<void> _openMomentDetails(MomentPhoto photo) async {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final entryService = context.read<EntryService>();
    final habitService = context.read<HabitService>();

    final Entry? entry = await entryService.getEntryByImageUrl(photo.habitId, photo.imageUrl);
    final Habit? habit = await habitService.watchHabit(photo.habitId).first;

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    if (entry != null && habit != null) {
      showDialog(
        context: context,
        builder: (context) => MomentDetailDialog(
          photo: photo,
          entry: entry,
          habitName: habit.name,
          unit: habit.unit,
        ),
      );
    }
  }

  Widget _buildPhotoTile(MomentPhoto photo) {
    return GestureDetector(
      onTap: () => _openMomentDetails(photo),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const ColoredBox(
                  color: Color(0xFFE2E8F0),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFE2E8F0),
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                );
              },
            ),
            if (photo.caption != null && photo.caption!.isNotEmpty)
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Gallery',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<MomentPhoto>>(
        stream: context.read<MomentService>().watchMomentsForUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final photos = snapshot.data ?? const <MomentPhoto>[];

          if (photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No photos yet',
                  style: TextStyle(color: textColorLight, fontSize: 16),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) => _buildPhotoTile(photos[index]),
          );
        },
      ),
    );
  }
}

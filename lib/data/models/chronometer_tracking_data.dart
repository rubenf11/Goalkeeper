class ChronometerTrackingData {
  final Duration elapsedTime;
  final bool isRecording;

  const ChronometerTrackingData({
    this.elapsedTime = Duration.zero,
    this.isRecording = false,
  });

  ChronometerTrackingData copyWith({Duration? elapsedTime, bool? isRecording}) {
    return ChronometerTrackingData(
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  String get elapsedFormatted {
    final h = elapsedTime.inHours;
    final m = elapsedTime.inMinutes.remainder(60);
    final s = elapsedTime.inSeconds.remainder(60);
    final two = (int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }
}

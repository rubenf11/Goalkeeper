class AccelerometerTrackingData {
  final int steps;
  final double distanceMeters;
  final Duration elapsedTime;
  final bool isRecording;

  const AccelerometerTrackingData({
    this.steps = 0,
    this.distanceMeters = 0.0,
    this.elapsedTime = Duration.zero,
    this.isRecording = false,
  });

  AccelerometerTrackingData copyWith({
    int? steps,
    double? distanceMeters,
    Duration? elapsedTime,
    bool? isRecording,
  }) {
    return AccelerometerTrackingData(
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  String get distanceFormatted {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.toStringAsFixed(1)} m';
  }

  String get elapsedFormatted {
    final h = elapsedTime.inHours;
    final m = elapsedTime.inMinutes.remainder(60);
    final s = elapsedTime.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

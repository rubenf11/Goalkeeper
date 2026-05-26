import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/chronometer_tracking_data.dart';
import 'background_recording_service.dart';

class _TimerSession {
  final String habitId;
  final String habitName;
  final DateTime startTime;

  _TimerSession({
    required this.habitId,
    required this.habitName,
    required this.startTime,
  });
}

class ChronometerTrackingService {
  static final ChronometerTrackingService _instance =
      ChronometerTrackingService._();
  factory ChronometerTrackingService() => _instance;
  ChronometerTrackingService._();

  Timer? _timer;
  final Map<String, _TimerSession> _sessions = {};

  final ValueNotifier<Map<String, ChronometerTrackingData>> allData =
      ValueNotifier({});

  bool get hasActiveSessions => _sessions.isNotEmpty;

  bool isRecording(String habitId) => _sessions.containsKey(habitId);

  ChronometerTrackingData? getData(String habitId) => allData.value[habitId];

  void startRecording({required String habitId, required String habitName}) {
    if (_sessions.containsKey(habitId)) return;

    final session = _TimerSession(
      habitId: habitId,
      habitName: habitName,
      startTime: DateTime.now(),
    );
    _sessions[habitId] = session;

    final data = ChronometerTrackingData(isRecording: true);
    allData.value = {...allData.value, habitId: data};

    BackgroundRecordingService().addSession(
      habitId: habitId,
      habitName: habitName,
      notificationBody: '00:00 elapsed',
    );

    if (_timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer _) {
    final now = DateTime.now();
    final newData = <String, ChronometerTrackingData>{};

    for (final session in _sessions.values) {
      final elapsed = now.difference(session.startTime);
      final data = ChronometerTrackingData(
        elapsedTime: elapsed,
        isRecording: true,
      );
      newData[session.habitId] = data;

      BackgroundRecordingService().updateSession(
        habitId: session.habitId,
        habitName: session.habitName,
        notificationBody: '${data.elapsedFormatted} elapsed',
        totalSessions: _sessions.length,
      );
    }

    allData.value = newData;
  }

  Duration? stopRecording(String habitId) {
    final session = _sessions.remove(habitId);
    if (session == null) return null;

    final elapsed = DateTime.now().difference(session.startTime);

    BackgroundRecordingService().removeSession(
      habitId: habitId,
      remainingSessions: _sessions.length,
    );

    final newData = Map<String, ChronometerTrackingData>.from(allData.value);
    newData.remove(habitId);
    allData.value = newData;

    if (_sessions.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }

    return elapsed;
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/accelerometer_tracking_data.dart';
import 'background_recording_service.dart';

class _Session {
  final String habitId;
  final String habitName;
  final String unit;
  final DateTime startTime;
  int initialSteps;
  int stepCount;
  bool initialCountCaptured;

  _Session({
    required this.habitId,
    required this.habitName,
    required this.unit,
    required this.startTime,
    required this.initialSteps,
    required this.stepCount,
    required this.initialCountCaptured,
  });
}

class AccelerometerTrackingService {
  static final AccelerometerTrackingService _instance =
      AccelerometerTrackingService._();
  factory AccelerometerTrackingService() => _instance;
  AccelerometerTrackingService._();

  StreamSubscription<StepCount>? _subscription;
  Timer? _timer;
  final Map<String, _Session> _sessions = {};

  static const double _strideLengthMeters = 0.75;

  final ValueNotifier<Map<String, AccelerometerTrackingData>> allData =
      ValueNotifier({});

  bool get hasActiveSessions => _sessions.isNotEmpty;

  bool isRecording(String habitId) => _sessions.containsKey(habitId);

  AccelerometerTrackingData? getData(String habitId) => allData.value[habitId];

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;
      final secondTry = await Permission.activityRecognition.request();
      return secondTry.isGranted;
    }
    return true;
  }

  static Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await Permission.activityRecognition.isGranted;
    }
    return true;
  }

  void startRecording({
    required String habitId,
    required String habitName,
    required String unit,
  }) {
    if (_sessions.containsKey(habitId)) return;

    final session = _Session(
      habitId: habitId,
      habitName: habitName,
      unit: unit,
      startTime: DateTime.now(),
      initialSteps: 0,
      stepCount: 0,
      initialCountCaptured: false,
    );
    _sessions[habitId] = session;

    final data = AccelerometerTrackingData(isRecording: true);
    allData.value = {...allData.value, habitId: data};

    BackgroundRecordingService().addSession(
      habitId: habitId,
      habitName: habitName,
      unit: unit,
      steps: 0,
      distanceMeters: 0.0,
      elapsed: '0s',
    );

    if (_subscription == null) {
      _subscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onError,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer _) {
    final now = DateTime.now();
    final newData = <String, AccelerometerTrackingData>{};

    for (final session in _sessions.values) {
      final data = AccelerometerTrackingData(
        steps: session.stepCount,
        distanceMeters: session.stepCount * _strideLengthMeters,
        elapsedTime: now.difference(session.startTime),
        isRecording: true,
      );
      newData[session.habitId] = data;

      BackgroundRecordingService().updateSession(
        habitId: session.habitId,
        habitName: session.habitName,
        unit: session.unit,
        steps: session.stepCount,
        distanceMeters: session.stepCount * _strideLengthMeters,
        elapsed: data.elapsedFormatted,
        totalSessions: _sessions.length,
        totalSteps: _totalSteps,
      );
    }

    allData.value = newData;
  }

  void _onStepCount(StepCount count) {
    for (final session in _sessions.values) {
      if (!session.initialCountCaptured) {
        session.initialSteps = count.steps;
        session.initialCountCaptured = true;
      } else {
        session.stepCount = count.steps - session.initialSteps;
        if (session.stepCount < 0) session.stepCount = 0;
      }
    }
  }

  void _onError(Object error) {
    debugPrint('Pedometer error: $error');
    for (final habitId in _sessions.keys.toList()) {
      stopRecording(habitId);
    }
  }

  int get _totalSteps =>
      _sessions.values.fold(0, (sum, s) => sum + s.stepCount);

  AccelerometerTrackingData? stopRecording(String habitId) {
    final session = _sessions.remove(habitId);
    if (session == null) return null;

    final data = AccelerometerTrackingData(
      steps: session.stepCount,
      distanceMeters: session.stepCount * _strideLengthMeters,
      elapsedTime: DateTime.now().difference(session.startTime),
      isRecording: false,
    );

    final remainingSteps = _totalSteps;

    BackgroundRecordingService().removeSession(
      habitId: habitId,
      remainingSessions: _sessions.length,
      totalSteps: remainingSteps,
    );

    final newData = Map<String, AccelerometerTrackingData>.from(allData.value);
    newData.remove(habitId);
    allData.value = newData;

    if (_sessions.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
      _timer?.cancel();
      _timer = null;
    }

    return data;
  }
}

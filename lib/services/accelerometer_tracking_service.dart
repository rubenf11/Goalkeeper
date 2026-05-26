import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/accelerometer_tracking_data.dart';
import 'background_recording_service.dart';

class AccelerometerTrackingService {
  StreamSubscription<StepCount>? _subscription;
  Timer? _timer;

  int _stepCount = 0;
  int _initialSteps = 0;
  bool _initialCountCaptured = false;
  DateTime? _startTime;

  static const double _strideLengthMeters = 0.75;

  final ValueNotifier<AccelerometerTrackingData> trackingData = ValueNotifier(
    const AccelerometerTrackingData(),
  );

  bool get isRecording => _subscription != null;

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

  void startRecording() {
    if (isRecording) return;

    _stepCount = 0;
    _initialSteps = 0;
    _initialCountCaptured = false;
    _startTime = DateTime.now();

    trackingData.value = const AccelerometerTrackingData(isRecording: true);

    BackgroundRecordingService().start(steps: 0, elapsed: '0s');

    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onError,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      trackingData.value = trackingData.value.copyWith(
        steps: _stepCount,
        distanceMeters: _stepCount * _strideLengthMeters,
        elapsedTime: DateTime.now().difference(_startTime!),
      );
      BackgroundRecordingService().update(
        steps: _stepCount,
        elapsed: trackingData.value.elapsedFormatted,
      );
    });
  }

  void _onStepCount(StepCount count) {
    if (!_initialCountCaptured) {
      _initialSteps = count.steps;
      _initialCountCaptured = true;
      return;
    }

    _stepCount = count.steps - _initialSteps;
    if (_stepCount < 0) _stepCount = 0;

    trackingData.value = trackingData.value.copyWith(
      steps: _stepCount,
      distanceMeters: _stepCount * _strideLengthMeters,
    );
  }

  void _onError(Object error) {
    debugPrint('Pedometer error: $error');
    stopRecording();
  }

  (int steps, double distanceMeters) stopRecording() {
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;

    BackgroundRecordingService().stop();

    if (_startTime != null) {
      trackingData.value = trackingData.value.copyWith(
        elapsedTime: DateTime.now().difference(_startTime!),
        isRecording: false,
      );
    }

    _startTime = null;

    return (_stepCount, _stepCount * _strideLengthMeters);
  }

  void dispose() {
    stopRecording();
    trackingData.dispose();
  }
}

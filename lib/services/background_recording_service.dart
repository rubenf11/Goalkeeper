import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _notificationChannelId = 'goal_keeper_recording';
const String _notificationChannelName = 'Recording Service';
const String _notificationChannelDesc = 'Shows when a habit is being recorded';
const int _foregroundNotificationId = 888;

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

String _progressText(int steps, double distanceMeters, String unit) {
  switch (unit) {
    case 'steps':
      return '$steps steps';
    case 'km':
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    case 'miles':
      return '${(distanceMeters / 1609.34).toStringAsFixed(2)} mi';
    default:
      return '${distanceMeters.toStringAsFixed(1)} m';
  }
}

class BackgroundRecordingService {
  static final BackgroundRecordingService _instance =
      BackgroundRecordingService._();
  factory BackgroundRecordingService() => _instance;
  BackgroundRecordingService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await FlutterBackgroundService().configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: (instance) {},
        onBackground: (instance) => true,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onAndroidStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'GoalKeeper',
        initialNotificationContent: 'No active recordings',
        foregroundServiceNotificationId: _foregroundNotificationId,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onAndroidStart(ServiceInstance service) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  Future<void> _ensureForegroundService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> _updateForegroundNotification({
    int sessionCount = 0,
    int totalSteps = 0,
  }) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      indeterminate: false,
      ongoing: true,
      onlyAlertOnce: true,
    );
    await _notifications.show(
      _foregroundNotificationId,
      'GoalKeeper',
      sessionCount > 0
          ? '$sessionCount habit${sessionCount > 1 ? 's' : ''} · $totalSteps steps total'
          : 'No active recordings',
      NotificationDetails(android: androidDetails),
    );
  }

  void addSession({
    required String habitId,
    required String habitName,
    required String unit,
    required int steps,
    required double distanceMeters,
    required String elapsed,
  }) {
    _ensureForegroundService();
    _postHabitNotification(
      habitId: habitId,
      habitName: habitName,
      unit: unit,
      steps: steps,
      distanceMeters: distanceMeters,
      elapsed: elapsed,
    );
  }

  void updateSession({
    required String habitId,
    required String habitName,
    required String unit,
    required int steps,
    required double distanceMeters,
    required String elapsed,
    required int totalSessions,
    required int totalSteps,
  }) {
    _postHabitNotification(
      habitId: habitId,
      habitName: habitName,
      unit: unit,
      steps: steps,
      distanceMeters: distanceMeters,
      elapsed: elapsed,
    );
    _updateForegroundNotification(
      sessionCount: totalSessions,
      totalSteps: totalSteps,
    );
  }

  void removeSession({
    required String habitId,
    required int remainingSessions,
    required int totalSteps,
  }) {
    _notifications.cancel(_notificationId(habitId));
    if (remainingSessions > 0) {
      _updateForegroundNotification(
        sessionCount: remainingSessions,
        totalSteps: totalSteps,
      );
    } else {
      _stop();
    }
  }

  int _notificationId(String habitId) => 1000 + habitId.hashCode.abs() % 900000;

  Future<void> _postHabitNotification({
    required String habitId,
    required String habitName,
    required String unit,
    required int steps,
    required double distanceMeters,
    required String elapsed,
  }) async {
    if (!_initialized) return;

    final progress = _progressText(steps, distanceMeters, unit);

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      indeterminate: false,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _notifications.show(
      _notificationId(habitId),
      habitName,
      '$progress | $elapsed',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    await _notifications.cancel(_foregroundNotificationId);
  }
}

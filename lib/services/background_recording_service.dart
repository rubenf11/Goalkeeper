import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _notificationChannelId = 'goal_keeper_recording';
const String _notificationChannelName = 'Recording Service';
const String _notificationChannelDesc = 'Shows when a habit is being recorded';
const int _notificationId = 888;

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

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
        initialNotificationTitle: 'Recording...',
        initialNotificationContent: 'Tracking your activity',
        foregroundServiceNotificationId: _notificationId,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onAndroidStart(ServiceInstance service) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  Future<void> start({int steps = 0, String elapsed = '0s'}) async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    await _updateNotification(steps: steps, elapsed: elapsed);
  }

  Future<void> update({int steps = 0, String elapsed = '0s'}) async {
    if (!_initialized) return;
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) return;

    await _updateNotification(steps: steps, elapsed: elapsed);
  }

  Future<void> _updateNotification({
    int steps = 0,
    String elapsed = '0s',
  }) async {
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
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    await _notifications.show(
      _notificationId,
      'Recording...',
      'Steps: $steps | Time: $elapsed',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    await _notifications.cancel(_notificationId);
  }
}

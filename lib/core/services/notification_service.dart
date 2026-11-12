import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/data/notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'suara_siswa_channel_v1';
  static const String channelName = 'Pemberitahuan SuaraSiswa';
  static const String channelDescription =
      'Notifikasi pesan baru, laporan masuk, dan info penting sekolah';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create High-Priority Notification Channel for Android
    final androidNotificationPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      await androidNotificationPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Request notification permission (Android 13+)
      await androidNotificationPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Background syncer that listens for new notifications from Cloudflare D1
/// and triggers native Android status bar pop-up notifications.
class NotificationSyncManager {
  final Ref _ref;
  Timer? _timer;
  final Set<String> _alertedIds = {};

  NotificationSyncManager(this._ref);

  void start() {
    _initAlertedCache();
    // Check initially
    _checkForNewNotifications();
    // Poll every 20 seconds for new incoming alerts
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkForNewNotifications();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _initAlertedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('alerted_notification_ids') ?? [];
      _alertedIds.addAll(saved);
    } catch (_) {}
  }

  Future<void> _saveAlertedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep last 100 IDs
      final list = _alertedIds.toList();
      final toSave = list.length > 100 ? list.sublist(list.length - 100) : list;
      await prefs.setStringList('alerted_notification_ids', toSave);
    } catch (_) {}
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final res = await repo.getNotifications();
      if (!res.success || res.data == null) return;

      final notifs = res.data!;
      for (final n in notifs) {
        // If unread and haven't popped up a local notification yet
        if (!n.isRead && !_alertedIds.contains(n.id)) {
          _alertedIds.add(n.id);
          await NotificationService().showNotification(
            id: n.id.hashCode,
            title: n.title,
            body: n.body,
            payload: n.referenceId,
          );
        }
      }
      await _saveAlertedCache();
    } catch (e) {
      debugPrint('Notification sync error: $e');
    }
  }
}

final notificationSyncManagerProvider = Provider<NotificationSyncManager>((ref) {
  final manager = NotificationSyncManager(ref);
  ref.onDispose(() => manager.stop());
  return manager;
});

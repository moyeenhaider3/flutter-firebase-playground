import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// LocalNotificationsService encapsulates flutter_local_notifications setup
/// and display helpers. This is used to show notifications when the app is in
/// foreground and to handle tap actions consistently.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin for Android and iOS.
  Future<void> init({required void Function(String? payload) onSelect}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    try {
      await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: (resp) {
        // Unified callback for taps on notifications
        final payload = resp.payload;
        onSelect(payload);
      });
    } catch (e, st) {
      developer.log('LocalNotifications init error: $e', stackTrace: st);
    }
  }

  /// Display a simple notification with optional payload for navigation.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e, st) {
      developer.log('LocalNotifications show error: $e', stackTrace: st);
    }
  }

  /// Android 13+ requires runtime permission for posting notifications.
  /// Call this to request permission explicitly.
  Future<void> requestAndroidPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final dynamic dyn = androidImpl;
      if (dyn != null) {
        try {
          // Method name varies across versions; try both
          await dyn.requestPermission();
        } catch (_) {
          try {
            await dyn.requestNotificationsPermission();
          } catch (e) {
            developer.log('Android notifications permission request failed: $e');
          }
        }
      }
    } catch (e, st) {
      developer.log('LocalNotifications android permission error: $e', stackTrace: st);
    }
  }

  /// Check if notifications are enabled on Android (13+ in particular).
  Future<bool?> areAndroidNotificationsEnabled() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled();
    } catch (e, st) {
      developer.log('LocalNotifications areNotificationsEnabled error: $e', stackTrace: st);
      return null;
    }
  }
}

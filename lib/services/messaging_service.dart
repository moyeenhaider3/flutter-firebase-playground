import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notifications_service.dart';

/// Top-level background handler. Must be a static or top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We can't navigate here, but we can show a notification
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title'] ?? 'Background Message';
  final body = notification?.body ?? data['body'] ?? 'You have a new message';

  await LocalNotificationsService.instance.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    payload: jsonEncode(data),
  );
}

/// MessagingService encapsulates FCM permissions, token handling, and message streams.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions (primarily for iOS, Android 13+ as well).
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      sound: true,
      provisional: false,
    );
    developer.log('Notification permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Get the current FCM token (may be null if permissions denied).
  Future<String?> getToken() => _messaging.getToken();

  /// Set up message listeners for foreground, background, and terminated states.
  Future<void> initListeners({required void Function(Map<String, dynamic> data) onTap}) async {
    // Ensure iOS shows alerts in foreground as well
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token refresh listener
    _messaging.onTokenRefresh.listen((token) {
      developer.log('FCM token refreshed: $token');
    });

    // Foreground messages: show a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      developer.log('onMessage: data=${message.data} notification=${message.notification}');
      final notification = message.notification;
      final data = message.data;
      final title = notification?.title ?? data['title'] ?? 'New Message';
      final body = notification?.body ?? data['body'] ?? '';
      await LocalNotificationsService.instance.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: jsonEncode(data),
      );
    });

    // App opened via notification tap from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('onMessageOpenedApp: data=${message.data}');
      onTap(message.data);
    });

    // Check if app was launched from terminated state by a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log('getInitialMessage: data=${initialMessage.data}');
      onTap(initialMessage.data);
    }

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

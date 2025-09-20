import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart' show NotificationSettings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/analytics_service.dart';
import '../services/local_notifications_service.dart';
import '../services/messaging_service.dart';
import '../widgets/info_card.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  String? _token;
  Map<String, dynamic>? _lastPayload;
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await MessagingService.instance.requestPermission();
    _settings = s;
    final token = await MessagingService.instance.getToken();
    setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    // Log screen view for Analytics parity
    AnalyticsService.instance.logScreenView(screenName: 'Messaging');

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('payload') && _lastPayload == null) {
      _lastPayload = args['payload'] as Map<String, dynamic>;
    }

    const samplePayload = '{\n  "route": "/details",\n  "id": "42",\n  "title": "New Item",\n  "body": "Tap to view details"\n}';

    return Scaffold(
      appBar: AppBar(title: const Text('Messaging Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                title: 'How to Test FCM',
                trailing: ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: samplePayload));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample data payload copied')),
                    );
                  },
                  child: const Text('Copy sample payload'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1) Open Firebase Console → Cloud Messaging → Send test message.'),
                    const Text('2) Paste the FCM token from this device.'),
                    const Text('3) Use a data payload to control routing (example below):'),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(samplePayload),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const InfoCard(
                title: 'Troubleshooting',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- iOS requires APNs setup and a real device for push.'),
                    Text('- Android 13+ requires POST_NOTIFICATIONS permission (requested at runtime).'),
                    Text('- Foreground notifications are shown using local notifications.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: 'Your Device & Permissions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FCM Token:'),
                    SelectableText(_token ?? 'Requesting permission / fetching token...'),
                    const SizedBox(height: 8),
                    Text('Permission status: ${_settings?.authorizationStatus.name ?? 'unknown'}'),
                    FutureBuilder<bool?>(
                      future: LocalNotificationsService.instance.areAndroidNotificationsEnabled(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
                        return Text('Android notifications enabled: ${snap.data ?? 'unknown'}');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: 'Last Notification Payload',
                child: Text(const JsonEncoder.withIndent('  ').convert(_lastPayload ?? {})),
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: 'Actions',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final t = await MessagingService.instance.getToken();
                        setState(() => _token = t);
                      },
                      child: const Text('Refresh Token'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await LocalNotificationsService.instance.requestAndroidPermission();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Requested Android 13+ notification permission')),
                        );
                      },
                      child: const Text('Request Notification Permission (Android 13+)'),
                    ),
                    ElevatedButton(
                      onPressed: _token == null
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: _token!));
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Token copied to clipboard')),
                              );
                            },
                      child: const Text('Copy Token'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Show a local notification without FCM to validate UI & tap handling
                        final payload = {
                          'route': '/details',
                          'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
                          'title': 'Local Test',
                          'body': 'This is a local test notification',
                        };
                        await LocalNotificationsService.instance.show(
                          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                          title: 'Local Test Notification',
                          body: 'Tap to navigate to Details',
                          payload: const JsonEncoder().convert(payload),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local notification shown')),
                        );
                      },
                      child: const Text('Send Local Test Notification'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

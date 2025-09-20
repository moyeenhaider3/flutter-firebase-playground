import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import '../services/analytics_service.dart';
import '../widgets/info_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreenView(screenName: 'Analytics');

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(title: 'Environment', child: _EnvBanner()),
              const SizedBox(height: 12),
              const InfoCard(
                title: 'About',
                child: Text('This screen logs custom events and explains how failures are handled.'),
              ),
              const SizedBox(height: 12),
              const InfoCard(title: 'How to Test', child: _HowToTestSection()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await AnalyticsService.instance.logEvent('tutorial_begin', {
                    'step': 1,
                    'context': 'analytics_screen',
                  });
                },
                child: const Text('Log tutorial_begin event'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  // Intentionally send a value that Analytics might reject to show error handling
                  await AnalyticsService.instance.logEvent('bad_event_name#', {
                    'invalid_param?': null, // null will be filtered out
                  });
                },
                child: const Text('Log intentionally malformed event (see console)'),
              ),
              const Divider(height: 32),
              InfoCard(title: 'User Identity & Properties', child: _UserIdPropertySection()),
              const SizedBox(height: 16),
              const Text('Tip: Run with Analytics DebugView to see events instantly.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserIdPropertySection extends StatefulWidget {
  @override
  State<_UserIdPropertySection> createState() => _UserIdPropertySectionState();
}

class _EnvBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final opts = DefaultFirebaseOptions.currentPlatform;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Firebase Project: ${opts.projectId}'),
          Text('App ID: ${opts.appId}'),
          Text('Sender ID: ${opts.messagingSenderId}'),
        ],
      ),
    );
  }
}

class _HowToTestSection extends StatelessWidget {
  const _HowToTestSection();

  @override
  Widget build(BuildContext context) {
    final package = 'com.example.flutter_firebase_playground';
    final cmd = 'adb shell setprop debug.firebase.analytics.app $package';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How to test Analytics (DebugView):'),
        const SizedBox(height: 8),
        const Text('1) Android: connect a device or start an emulator.'),
        Text('2) Run this once, then relaunch the app:\n$cmd'),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: cmd));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ADB command copied')),
                );
              },
              child: const Text('Copy ADB DebugView command'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('3) Open Firebase Console → Analytics → DebugView to see events in real-time.'),
        const Text('4) iOS: run on a simulator/device and open DebugView; no ADB step needed.'),
        const SizedBox(height: 8),
        const Text('Event naming rules: start with a letter; only letters, digits, and _; max 40 chars.'),
      ],
    );
  }
}

class _UserIdPropertySectionState extends State<_UserIdPropertySection> {
  final _userIdCtrl = TextEditingController();
  final _propNameCtrl = TextEditingController();
  final _propValueCtrl = TextEditingController();

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _propNameCtrl.dispose();
    _propValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User identity & properties'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'e.g. 12345',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final id = _userIdCtrl.text.trim();
                await AnalyticsService.instance.analytics.setUserId(id: id.isEmpty ? null : id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(id.isEmpty ? 'UserId cleared' : 'UserId set: $id')),
                );
              },
              child: const Text('Set UserId'),
            )
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _propNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  hintText: 'e.g. plan_tier',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _propValueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Property Value',
                  hintText: 'e.g. pro',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final name = _propNameCtrl.text.trim();
                final value = _propValueCtrl.text.trim();
                if (name.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Property name cannot be empty')),
                  );
                  return;
                }
                await AnalyticsService.instance.analytics.setUserProperty(name: name, value: value.isEmpty ? null : value);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User property set: $name = ${value.isEmpty ? '(null)' : value}')),
                );
              },
              child: const Text('Set Property'),
            ),
          ],
        )
      ],
    );
  }
}

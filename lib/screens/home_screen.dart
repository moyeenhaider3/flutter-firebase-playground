import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../widgets/info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsService.instance.logScreenView(screenName: 'Home');
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Playground')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: 'Welcome',
            child: Text(
              'This app demonstrates Firebase Core, Analytics, and Cloud Messaging (FCM) with local notifications. Use the cards below to explore demos.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics Demo',
            subtitle: 'Log events, set user ID/property, and learn how to use DebugView.',
            onTap: () => Navigator.pushNamed(context, '/analytics'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.notifications_active_outlined,
            title: 'Messaging Demo (FCM)',
            subtitle: 'See your FCM token, test pushes, and try local notifications.',
            onTap: () => Navigator.pushNamed(context, '/messaging'),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

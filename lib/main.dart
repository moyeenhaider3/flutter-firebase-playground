import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/analytics_screen.dart';
import 'screens/details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/messaging_screen.dart';
import 'services/analytics_service.dart';
import 'services/local_notifications_service.dart';
import 'services/messaging_service.dart';

// Ensure background handler is set up at top-level for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using generated options. This will throw a helpful
  // error until `flutterfire configure` is run to generate real values.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Initialize Analytics defaults using the configured FirebaseOptions
    await AnalyticsService.instance.initDefaults(DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    developer.log('Firebase init failed (expected before flutterfire configure): $e', stackTrace: st);
  }

  // Initialize local notifications and handle taps to navigate after app launch
  await LocalNotificationsService.instance.init(onSelect: (payload) {
    // Store payload in a static place or a navigator key if needed.
    // For simplicity, we log here. Actual navigation will be handled from onMessageOpenedApp/initialMessage.
    developer.log('Notification tapped with payload: $payload');
  });

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Start messaging listeners and route taps
    MessagingService.instance.initListeners(onTap: (data) {
      _handleNotificationTap(data);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Example payload shape: {"route":"/details","id":"42"}
    final route = data['route'] as String?;
    if (route == '/details') {
      final id = (data['id'] ?? '').toString();
      _navKey.currentState?.pushNamed('/details', arguments: {'id': id});
    } else {
      // Default: open messaging screen with payload visible
      _navKey.currentState?.pushNamed('/messaging', arguments: {'payload': data});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Playground',
      navigatorKey: _navKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
      ),
      navigatorObservers: [AnalyticsService.instance.observer],
      routes: {
        '/': (_) => const HomeScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/messaging': (_) => const MessagingScreen(),
        '/details': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          final id = (args?['id'] ?? '').toString();
          return DetailsScreen(id: id);
        },
      },
    );
  }
}

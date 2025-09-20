import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// AnalyticsService wraps Firebase Analytics calls so UI code stays clean.
///
/// Responsibilities:
/// - Hold a single `FirebaseAnalytics` instance
/// - Provide helper methods to log events and screen views with safe defaults
/// - Catch and log errors so freshers can see what would happen in a real app
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  /// Underlying Firebase Analytics singleton.
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Optional navigator observer to automatically track screen transitions.
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
        analytics: analytics,
      );

  /// Initialize analytics defaults using FirebaseOptions.
  /// This helps ensure events include core identifiers for compatibility
  /// across platforms (projectId, appId, senderId, measurementId if present).
  Future<void> initDefaults(FirebaseOptions options) async {
    try {
      await analytics.setAnalyticsCollectionEnabled(true);

      final Map<String, Object> defaults = {
        'firebase_project_id': options.projectId,
        'firebase_app_id': options.appId,
        'firebase_messaging_sender_id': options.messagingSenderId,
      };

      // measurementId exists on web/windows; add only if non-empty
      // FirebaseOptions doesn't expose nullable types, so we check by platform keys we know
      // and ignore when not applicable.
      // For safety, we attempt to access via toString and filter empties.
      final measurementId = _extractMeasurementIdIfAny(options);
      if (measurementId != null && measurementId.isNotEmpty) {
        defaults['firebase_measurement_id'] = measurementId;
      }

      await analytics.setDefaultEventParameters(defaults);
    } catch (e, st) {
      developer.log('Analytics initDefaults error: $e', stackTrace: st);
    }
  }

  // Best-effort extraction of measurementId from FirebaseOptions to support web/windows
  String? _extractMeasurementIdIfAny(FirebaseOptions options) {
    // FirebaseOptions doesn't have a direct getter for measurementId across platforms.
    // The generated firebase_options.dart includes measurementId only for web/windows,
    // but the field isn't available here. We return null to skip when not present.
    return null;
  }

  /// Log a custom event with parameters.
  /// Example: `logEvent('purchase', {'item_id': '123', 'value': 9.99})`.
  Future<void> logEvent(String name, [Map<String, Object?> parameters = const {}]) async {
    try {
      if (!_isValidEventName(name)) {
        await _logAppError('invalid_event_name', {'bad_name': name});
        return;
      }
      // FirebaseAnalytics currently expects Map<String, Object> (non-null values)
      final cleaned = Map<String, Object>.fromEntries(
        parameters.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value as Object)),
      );
      await analytics.logEvent(name: name, parameters: cleaned);
    } catch (e, st) {
      // In a real app, this would be captured by crash/analytics logger
      developer.log('Analytics logEvent error: $e', stackTrace: st);
      await _logAppError('analytics_log_error', {'error': e.toString()});
    }
  }

  /// Track a screen view explicitly.
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await analytics.logScreenView(screenName: screenName, screenClass: screenClass);
    } catch (e, st) {
      developer.log('Analytics logScreenView error: $e', stackTrace: st);
    }
  }

  bool _isValidEventName(String name) {
    // Firebase event names must be <= 40 chars, start with [a-zA-Z], and contain [a-zA-Z0-9_]
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');
    return regex.hasMatch(name);
  }

  Future<void> _logAppError(String code, Map<String, Object?> details) async {
    final cleaned = Map<String, Object>.fromEntries(
      details.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value as Object)),
    );
    try {
      await analytics.logEvent(name: 'app_error', parameters: {
        'code': code,
        ...cleaned,
      });
    } catch (_) {
      // swallow
    }
  }
}

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Set user context for crash reports
  static Future<void> setUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _crashlytics.setUserIdentifier(user.uid);
      await _crashlytics.setCustomKey('user_email', user.email ?? 'unknown');
      await _crashlytics.setCustomKey('user_display_name', user.displayName ?? 'unknown');
    }
  }

  /// Log a non-fatal error with context
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    // Set custom keys if provided
    if (customKeys != null) {
      for (final entry in customKeys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    }

    // Record the error
    await _crashlytics.recordError(
      exception,
      stackTrace,
      fatal: fatal,
    );
  }

  /// Log RSVP-related errors specifically
  static Future<void> recordRsvpError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? userId,
    String? sessionId,
    String? action,
  }) async {
    final customKeys = <String, dynamic>{
      'error_type': 'rsvp_error',
      'user_id': userId ?? 'unknown',
      'session_id': sessionId ?? 'unknown',
      'action': action ?? 'unknown',
    };

    await recordError(
      exception,
      stackTrace,
      customKeys: customKeys,
    );
  }

  /// Log authentication-related errors
  static Future<void> recordAuthError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? userId,
    String? email,
    String? action,
  }) async {
    final customKeys = <String, dynamic>{
      'error_type': 'auth_error',
      'user_id': userId ?? 'unknown',
      'user_email': email ?? 'unknown',
      'action': action ?? 'unknown',
    };

    await recordError(
      exception,
      stackTrace,
      customKeys: customKeys,
    );
  }

  /// Log push notification errors
  static Future<void> recordPushNotificationError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? userId,
    String? notificationType,
    String? action,
  }) async {
    final customKeys = <String, dynamic>{
      'error_type': 'push_notification_error',
      'user_id': userId ?? 'unknown',
      'notification_type': notificationType ?? 'unknown',
      'action': action ?? 'unknown',
    };

    await recordError(
      exception,
      stackTrace,
      customKeys: customKeys,
    );
  }

  /// Log a custom message (non-error)
  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Test crashlytics (for testing purposes only)
  static Future<void> testCrash() async {
    throw Exception('Test crash for Crashlytics');
  }
}

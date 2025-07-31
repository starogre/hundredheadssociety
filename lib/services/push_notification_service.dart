import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Initialize push notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        saveFCMTokenForCurrentUser();
        if (kDebugMode) {
          print('FCM Token refreshed: $token');
        }
      });

      // Save FCM token for current user if available
      if (_fcmToken != null) {
        await saveFCMTokenForCurrentUser();
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notifications: $e');
      }
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    }

    // Show local notification
    _showLocalNotification(message);
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }

    // Handle navigation based on notification payload
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      // This will be implemented based on your navigation structure
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hundred_heads_channel',
      '100 Heads Society',
      channelDescription: 'Notifications for 100 Heads Society app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This will be implemented based on your app's navigation structure
    // For now, we'll just log the data
    if (kDebugMode) {
      print('Navigation data: $data');
    }
  }

  // Update FCM token in Firestore
  Future<void> _updateFCMTokenInFirestore() async {
    // This will be called when the user is logged in
    // We'll implement this in the auth service
  }

  // Save FCM token for current user
  Future<void> saveFCMTokenForCurrentUser() async {
    if (_fcmToken != null) {
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          await _firestore.collection('users').doc(auth.currentUser!.uid).update({
            'fcmToken': _fcmToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
          if (kDebugMode) {
            print('FCM token saved for user: ${auth.currentUser!.uid}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token for current user: $e');
        }
      }
    }
  }

  // Send RSVP confirmation notification
  Future<void> sendRSVPConfirmation(String userId, String sessionTitle, DateTime sessionDate) async {
    try {
      // Create notification in Firestore - this will automatically trigger the Cloud Function
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'rsvp_confirmation',
        'title': 'RSVP Confirmed!',
        'message': 'You\'re confirmed for $sessionTitle on ${_formatDate(sessionDate)}',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'sessionDate': Timestamp.fromDate(sessionDate),
          'action': 'rsvp_confirmed'
        }
      });

      // The Cloud Function will automatically send the push notification
      // when the notification document is created in Firestore

    } catch (e) {
      if (kDebugMode) {
        print('Error sending RSVP confirmation: $e');
      }
    }
  }

  // Send push notification via Cloud Functions
  Future<void> _sendPushNotification(String userId, String title, String body, {Map<String, dynamic>? data}) async {
    try {
      if (kDebugMode) {
        print('Sending push notification to user $userId: $title - $body');
      }

      // Call the Cloud Function to send push notification
      final httpsCallable = FirebaseFunctions.instance.httpsCallable('testPushNotification');
      
      final result = await httpsCallable.call({
        'userId': userId,
        'title': title,
        'body': body,
      });

      if (kDebugMode) {
        print('Push notification sent successfully: ${result.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification: $e');
      }
    }
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Get FCM token for a user
  Future<String?> getFCMTokenForUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['fcmToken'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token for user: $e');
      }
      return null;
    }
  }

  // Save FCM token for a user
  Future<void> saveFCMTokenForUser(String userId) async {
    if (_fcmToken != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token for user: $e');
        }
      }
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  // await Firebase.initializeApp();

  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
} 
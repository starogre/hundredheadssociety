import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/user_management_screen.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  
  // Set navigator key for push notification navigation
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

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
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        saveFCMTokenForCurrentUser();
        if (kDebugMode) {
          debugPrint('FCM Token refreshed: $token');
        }
      });

      // Save FCM token for current user if available
      if (_fcmToken != null) {
        await saveFCMTokenForCurrentUser();
      }

      // Also save token after a short delay to ensure it's available
      Future.delayed(const Duration(seconds: 2), () async {
        if (_fcmToken != null) {
          await saveFCMTokenForCurrentUser();
        }
      });

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
        debugPrint('Error initializing push notifications: $e');
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
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    }

    // Show local notification
    _showLocalNotification(message);
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${message.data}');
    }

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Local notification tapped: ${response.payload}');
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
    if (kDebugMode) {
      debugPrint('Navigation data: $data');
    }
    
    // Get the current context from the navigator key
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('No navigation context available for push notification');
      }
      return;
    }
    
    try {
      // Handle different notification types based on data
      final action = data['action'] as String?;
      final navigateTo = data['navigateTo'] as String?;
      
      if (navigateTo == 'weekly_sessions' || action == 'rsvp_reminder' || action == 'rsvp_confirmed') {
        // Navigate to weekly sessions screen
        Navigator.of(context).pushNamed('/weekly-sessions');
      } else if (action == 'upgrade_request') {
        // Navigate to user management with upgrade requests tab
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => UserManagementScreen(initialTab: 3),
        ));
      } else if (action == 'new_artist_signup') {
        // Navigate to user management with approvals tab
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => UserManagementScreen(initialTab: 2),
        ));
      } else {
        // Default to home/dashboard
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error handling notification navigation: $e');
      }
      // Fallback: navigate to home
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('Fallback navigation also failed: $fallbackError');
        }
      }
    }
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
            debugPrint('FCM token saved for user: ${auth.currentUser!.uid}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error saving FCM token for current user: $e');
        }
      }
    }
  }

  // Send RSVP confirmation notification
  Future<void> sendRSVPConfirmation(String userId, String sessionTitle, DateTime sessionDate) async {
    try {
      // Always create in-app notification in Firestore
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

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending RSVP confirmation: $e');
      }
    }
  }

  // Send session reminder notification
  Future<void> sendSessionReminder(String userId, String sessionTitle, DateTime sessionDate) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'session_reminder',
        'title': 'Weekly Session Tomorrow!',
        'message': 'Don\'t forget! The weekly session starts tomorrow at 6:00 PM. Please RSVP if you haven\'t already.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'sessionDate': Timestamp.fromDate(sessionDate),
          'action': 'session_reminder'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending session reminder: $e');
      }
    }
  }



  // Send award notification
  Future<void> sendAwardNotification(String userId, String awardTitle, String awardDescription) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'award_notification',
        'title': '🎉 You Won an Award!',
        'message': 'Congratulations! You won "$awardTitle" - $awardDescription',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'awardTitle': awardTitle,
          'awardDescription': awardDescription,
          'action': 'award_won'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending award notification: $e');
      }
    }
  }

  // Send admin approval notification
  Future<void> sendAdminApprovalNotification(String userId, String userName, String userRole) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'admin_approval',
        'title': 'Account Approved!',
        'message': 'Your account has been approved! You can now access all features.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'userName': userName,
          'userRole': userRole,
          'action': 'account_approved'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending admin approval notification: $e');
      }
    }
  }

  // Send admin rejection notification
  Future<void> sendAdminRejectionNotification(String userId, String userName, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'admin_rejection',
        'title': 'Account Update',
        'message': 'Your account application has been reviewed. Please check your email for details.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'userName': userName,
          'reason': reason,
          'action': 'account_reviewed'
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending admin rejection notification: $e');
      }
    }
  }

  // Send milestone notification
  Future<void> sendMilestoneNotification(String userId, String milestoneType, int count) async {
    try {
      String title = '';
      String message = '';
      
      switch (milestoneType) {
        case 'portraits':
          title = '🎨 Portrait Milestone!';
          message = 'Congratulations! You\'ve completed $count portraits!';
          break;
        case 'sessions':
          title = '📅 Session Milestone!';
          message = 'Amazing! You\'ve participated in $count weekly sessions!';
          break;
        case 'votes':
          title = '🗳️ Voting Milestone!';
          message = 'Great job! You\'ve cast $count votes for your fellow artists!';
          break;
      }

      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'milestone',
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'milestoneType': milestoneType,
          'count': count,
          'action': 'milestone_reached'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending milestone notification: $e');
      }
    }
  }

  // Send upload deadline reminder (Tuesday noon)
  Future<void> sendUploadDeadlineReminder(String userId, String sessionTitle) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'upload_deadline',
        'title': '📤 Upload Your Portrait!',
        'message': 'Don\'t forget to upload your portrait for this week\'s session!',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'action': 'upload_reminder'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending upload deadline reminder: $e');
      }
    }
  }

  // Send voting reminder (Wednesday 1 hour before close)
  Future<void> sendVotingReminder(String userId, String sessionTitle) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'voting_reminder',
        'title': '🗳️ Vote Now!',
        'message': 'Voting closes in 1 hour! Don\'t forget to vote for your favorite portraits!',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'action': 'voting_reminder'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending voting reminder: $e');
      }
    }
  }

  // Send RSVP reminder (Saturday noon with navigation)
  Future<void> sendRSVPReminder(String userId, String sessionTitle, DateTime sessionDate) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'rsvp_reminder',
        'title': '📅 RSVP for Monday\'s Session',
        'message': 'Will you be joining us for this week\'s session? Please RSVP!',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'sessionDate': Timestamp.fromDate(sessionDate),
          'action': 'rsvp_reminder',
          'navigateTo': 'weekly_sessions'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending RSVP reminder: $e');
      }
    }
  }

  // Send account approval (push only, no in-app)
  Future<void> sendAccountApprovalPushOnly(String userId, String userName) async {
    try {
      // This will be handled by Cloud Functions to send push notification only
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'account_approval_push',
        'title': 'Account Approved!',
        'message': 'Your account has been approved! You can now access all features.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'userName': userName,
          'action': 'account_approved',
          'pushOnly': true
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending account approval notification: $e');
      }
    }
  }

  // Send session cancellation notification
  Future<void> sendSessionCancellationNotification(String userId, String sessionTitle, DateTime sessionDate) async {
    try {
      // Always create in-app notification in Firestore
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'userId': userId,
        'type': 'session_cancelled',
        'title': '❌ 100 Heads Portrait Night Cancelled',
        'message': 'This week\'s portrait night on ${_formatDate(sessionDate)} has been cancelled. Check the weekly sessions screen for details and next week\'s schedule.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'sessionTitle': sessionTitle,
          'sessionDate': Timestamp.fromDate(sessionDate),
          'action': 'session_cancelled',
          'navigateTo': 'weekly_sessions'
        }
      });

      // The Cloud Function will check user preferences and send push notification if enabled

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending session cancellation notification: $e');
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
        debugPrint('Error getting FCM token for user: $e');
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
        debugPrint('Error saving FCM token for user: $e');
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
    debugPrint('Handling a background message: ${message.messageId}');
  }
} 
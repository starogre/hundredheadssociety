import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get unread notifications
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((notification) => !notification.read).toList();

  // Initialize notifications for a user
  Future<void> initializeNotifications(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Listen to notifications stream
      _notificationService.getNotificationsStream(userId).listen(
        (notifications) {
          _notifications = notifications;
          _unreadCount = notifications.where((n) => !n.read).length;
          debugPrint('NotificationProvider: Received ${notifications.length} notifications, ${_unreadCount} unread');
          debugPrint('NotificationProvider: Calling notifyListeners()');
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load notifications: $error');
        }
      );

      // Listen to unread count stream
      _notificationService.getUnreadCount(userId).listen(
        (count) {
          _unreadCount = count;
          debugPrint('NotificationProvider: Unread count updated to $count');
          debugPrint('NotificationProvider: Calling notifyListeners() from unread count stream');
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error listening to unread count: $error');
        }
      );
      
    } catch (error) {
      _setError('Failed to initialize notifications: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notificationService.markAsRead(userId, notificationId);
      // The stream will automatically update the UI
    } catch (error) {
      _setError('Failed to mark notification as read: $error');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      // The stream will automatically update the UI
    } catch (error) {
      _setError('Failed to mark all notifications as read: $error');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationService.deleteNotification(userId, notificationId);
      // The stream will automatically update the UI
    } catch (error) {
      _setError('Failed to delete notification: $error');
    }
  }

  // Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(String userId, String type) async {
    try {
      return await _notificationService.getNotificationsByType(userId, type);
    } catch (error) {
      _setError('Failed to get notifications by type: $error');
      return [];
    }
  }

  // Get recent notifications
  Future<List<NotificationModel>> getRecentNotifications(String userId) async {
    try {
      return await _notificationService.getRecentNotifications(userId);
    } catch (error) {
      _setError('Failed to get recent notifications: $error');
      return [];
    }
  }

  // Clear old notifications
  Future<void> clearOldNotifications(String userId) async {
    try {
      await _notificationService.clearOldNotifications(userId);
      // The stream will automatically update the UI
    } catch (error) {
      _setError('Failed to clear old notifications: $error');
    }
  }

  // Create test notification (for development)
  Future<void> createTestNotification(String userId) async {
    try {
      await _notificationService.createTestNotification(userId);
      // The stream will automatically update the UI
    } catch (error) {
      _setError('Failed to create test notification: $error');
    }
  }

  // Get notifications by session
  List<NotificationModel> getNotificationsForSession(String sessionId) {
    return _notifications.where((notification) => 
        notification.sessionId == sessionId).toList();
  }

  // Get session-related notifications
  List<NotificationModel> getSessionNotifications() {
    return _notifications.where((notification) => 
        notification.isSessionCreated ||
        notification.isSessionReminder ||
        notification.isRSVPConfirmation ||
        notification.isNewSubmission ||
        notification.isSessionCompleted).toList();
  }

  // Check if user has any unread session notifications
  bool hasUnreadSessionNotifications() {
    return _notifications.any((notification) => 
        !notification.read && 
        (notification.isSessionCreated ||
         notification.isSessionReminder ||
         notification.isRSVPConfirmation ||
         notification.isNewSubmission ||
         notification.isSessionCompleted));
  }

  // Get latest session notification
  NotificationModel? getLatestSessionNotification() {
    final sessionNotifications = getSessionNotifications();
    if (sessionNotifications.isEmpty) return null;
    return sessionNotifications.first; // Already sorted by createdAt desc
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log_model.dart';

class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log an activity
  Future<void> logActivity({
    required String action,
    required String performedBy,
    required String performedByName,
    String? targetUserId,
    String? targetUserName,
    Map<String, dynamic>? details,
  }) async {
    try {
      final activityLog = ActivityLogModel(
        id: '', // Will be set by Firestore
        action: action,
        performedBy: performedBy,
        performedByName: performedByName,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        details: details,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('activity_logs').add(activityLog.toMap());
      print('Activity logged: ${activityLog.description}');
    } catch (e) {
      print('Error logging activity: $e');
      // Don't rethrow - we don't want activity logging to break the main functionality
    }
  }

  // Get all activity logs, ordered by timestamp (newest first)
  Stream<List<ActivityLogModel>> getActivityLogs() {
    return _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 entries for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get activity logs for a specific user
  Stream<List<ActivityLogModel>> getActivityLogsForUser(String userId) {
    return _firestore
        .collection('activity_logs')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get activity logs performed by a specific user
  Stream<List<ActivityLogModel>> getActivityLogsByUser(String userId) {
    return _firestore
        .collection('activity_logs')
        .where('performedBy', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
} 
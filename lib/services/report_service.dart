import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Report a portrait
  Future<void> reportPortrait({
    required String portraitId,
    required String reportedUserId,
    required String reportedUserName,
    required String reporterUserId,
    required String reporterName,
    required String reason,
    String? details,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reportType': 'portrait',
        'reportedItemId': portraitId,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterUserId': reporterUserId,
        'reporterName': reporterName,
        'reason': reason,
        'details': details ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'resolution': null,
        'actionTaken': 'none',
      });
      
      debugPrint('Portrait report submitted successfully');
    } catch (e) {
      debugPrint('Error reporting portrait: $e');
      rethrow;
    }
  }

  // Report a user
  Future<void> reportUser({
    required String reportedUserId,
    required String reportedUserName,
    required String reporterUserId,
    required String reporterName,
    required String reason,
    String? details,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reportType': 'user',
        'reportedItemId': reportedUserId,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterUserId': reporterUserId,
        'reporterName': reporterName,
        'reason': reason,
        'details': details ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'resolution': null,
        'actionTaken': 'none',
      });
      
      debugPrint('User report submitted successfully');
    } catch (e) {
      debugPrint('Error reporting user: $e');
      rethrow;
    }
  }

  // Report a submission
  Future<void> reportSubmission({
    required String sessionId,
    required String submissionId,
    required String reportedUserId,
    required String reportedUserName,
    required String reporterUserId,
    required String reporterName,
    required String reason,
    String? details,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reportType': 'submission',
        'reportedItemId': submissionId,
        'sessionId': sessionId,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterUserId': reporterUserId,
        'reporterName': reporterName,
        'reason': reason,
        'details': details ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'resolution': null,
        'actionTaken': 'none',
      });
      
      debugPrint('Submission report submitted successfully');
    } catch (e) {
      debugPrint('Error reporting submission: $e');
      rethrow;
    }
  }

  // Get all reports (admin only)
  Stream<List<Map<String, dynamic>>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get pending reports only (admin only)
  Stream<List<Map<String, dynamic>>> getPendingReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update report status (admin only)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String reviewedBy,
    String? resolution,
    String? actionTaken,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (resolution != null) updates['resolution'] = resolution;
      if (actionTaken != null) updates['actionTaken'] = actionTaken;

      await _firestore.collection('reports').doc(reportId).update(updates);
      
      debugPrint('Report status updated successfully');
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  // Delete a report (admin only)
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      debugPrint('Report deleted successfully');
    } catch (e) {
      debugPrint('Error deleting report: $e');
      rethrow;
    }
  }

  // Get report count for badge (admin only)
  Stream<int> getPendingReportCount() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}


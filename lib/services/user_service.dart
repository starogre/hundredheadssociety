import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/portrait_model.dart';
import '../models/upgrade_request_model.dart';
import 'activity_log_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users for community view
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('portraitsCompleted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user portraits with pagination
  Future<PortraitPaginationResult> getUserPortraitsPaginated(
    String userId, {
    int limit = 6,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .orderBy('weekNumber', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      
      List<PortraitModel> portraits = snapshot.docs
          .map((doc) => PortraitModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      
      return PortraitPaginationResult(
        portraits: portraits,
        lastDocument: lastDoc,
      );
    } catch (e) {
      debugPrint('Error in getUserPortraitsPaginated: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? profileImageUrl,
    String? instagram,
    String? contactEmail,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (instagram != null) updates['instagram'] = instagram;
      if (contactEmail != null) updates['contactEmail'] = contactEmail;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Get users with most portraits (leaderboard)
  Stream<List<UserModel>> getTopUsers({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('portraitsCompleted', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Search users by name
  Stream<List<UserModel>> searchUsers(String searchTerm) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThan: searchTerm + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Create a new user
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete a user (for admin deletion through User Management)
  // This uses the same comprehensive data deletion as user self-deletion
  // Note: Does NOT delete Firebase Auth (admin can't delete another user's auth)
  Future<void> deleteUser(String userId, {
    String? performedBy,
    String? performedByName,
  }) async {
    final ActivityLogService _activityLogService = ActivityLogService();
    
    try {
      // Get the user data BEFORE deleting to log their name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final targetUserName = userData?['name'] ?? 'Unknown User';
      
      // Use comprehensive data deletion (portraits, submissions, votes, etc.)
      await _deleteUserData(userId);
      
      // Log the activity if admin info is provided
      if (performedBy != null && performedByName != null) {
        await _activityLogService.logActivity(
          action: 'user_deleted',
          performedBy: performedBy,
          performedByName: performedByName,
          targetUserId: userId,
          targetUserName: targetUserName,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user's admin status
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Approve a user
  Future<void> approveUser(String userId, {
    String? performedBy,
    String? performedByName,
  }) async {
    final ActivityLogService _activityLogService = ActivityLogService();
    
    try {
      // Get the user data before updating to log their name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final targetUserName = userData?['name'] ?? 'Unknown User';
      
      await _firestore.collection('users').doc(userId).update({
        'status': 'approved',
      });
      
      // Log the activity if admin info is provided
      if (performedBy != null && performedByName != null) {
        await _activityLogService.logActivity(
          action: 'user_approved',
          performedBy: performedBy,
          performedByName: performedByName,
          targetUserId: userId,
          targetUserName: targetUserName,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Deny a user
  Future<void> denyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'denied',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Upgrade Request Methods

  // Create an upgrade request
  Future<void> createUpgradeRequest({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    try {
      debugPrint('=== UPGRADE REQUEST DEBUG ===');
      debugPrint('Attempting to create upgrade request for user: $userId');
      debugPrint('User email: $userEmail');
      debugPrint('User name: $userName');
      
      // Check if user already has a pending request
      final existingRequests = await _firestore
          .collection('upgrade_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

              debugPrint('Found ${existingRequests.docs.length} existing pending requests');

      if (existingRequests.docs.isNotEmpty) {
                  debugPrint('User already has a pending request, throwing exception');
        throw Exception('You already have a pending upgrade request');
      }

      final request = UpgradeRequestModel(
        id: '', // Will be set by Firestore
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        requestedAt: DateTime.now(),
        status: 'pending',
      );

              debugPrint('Creating upgrade request document...');
      final docRef = await _firestore.collection('upgrade_requests').add(request.toMap());
              debugPrint('Upgrade request created successfully with ID: ${docRef.id}');

      // Send notification to admins
              debugPrint('Sending notification to admins...');
      await _sendUpgradeRequestNotificationToAdmins(userId, userName);
              debugPrint('Notification sent successfully');
        debugPrint('=== UPGRADE REQUEST COMPLETE ===');
    } catch (e) {
              debugPrint('=== UPGRADE REQUEST ERROR ===');
        debugPrint('Error creating upgrade request: $e');
        debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Placeholder for sending notification to admins/moderators
  Future<void> _sendUpgradeRequestNotificationToAdmins(String userId, String userName) async {
    try {
      // Get all admin users
      final adminUsers = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      // Create notification for each admin
      final batch = _firestore.batch();
      
      for (final adminDoc in adminUsers.docs) {
        final adminId = adminDoc.id;
        
        // Create notification in admin's notifications subcollection
        final notificationRef = _firestore
            .collection('users')
            .doc(adminId)
            .collection('notifications')
            .doc();

        final notification = {
          'userId': adminId,
          'type': 'upgrade_request',
          'title': 'New Artist Upgrade Request',
          'message': '$userName has requested to upgrade from Art Appreciator to Artist',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'read': false,
          'data': {
            'requestingUserId': userId,
            'requestingUserName': userName,
            'action': 'view_upgrade_requests',
          },
        };

        batch.set(notificationRef, notification);
      }

      await batch.commit();
    } catch (e) {
      // Log error but don't fail the upgrade request creation
              debugPrint('Error sending admin notifications: $e');
    }
  }

  // Get all upgrade requests
  Stream<List<UpgradeRequestModel>> getUpgradeRequests() {
    return _firestore
        .collection('upgrade_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UpgradeRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get pending upgrade requests
  Stream<List<UpgradeRequestModel>> getPendingUpgradeRequests() {
    return _firestore
        .collection('upgrade_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UpgradeRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Approve an upgrade request
  Future<void> approveUpgradeRequest({
    required String requestId,
    required String adminId,
    required String adminName,
  }) async {
    final ActivityLogService _activityLogService = ActivityLogService();
    
    try {
      final batch = _firestore.batch();

      // Update the upgrade request
      final requestRef = _firestore.collection('upgrade_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'adminId': adminId,
        'adminName': adminName,
        'processedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get the request to find the user ID
      final requestDoc = await requestRef.get();
      final requestData = requestDoc.data();
      if (requestData != null) {
        final userId = requestData['userId'] as String;
        final userName = requestData['userName'] as String;
        
        // Update the user's role to artist
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'userRole': 'artist',
        });
        
        // Log the activity
        await _activityLogService.logActivity(
          action: 'user_approved',
          performedBy: adminId,
          performedByName: adminName,
          targetUserId: userId,
          targetUserName: userName,
        );
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Deny an upgrade request
  Future<void> denyUpgradeRequest({
    required String requestId,
    required String adminId,
    required String adminName,
    required String reason,
  }) async {
    try {
      await _firestore.collection('upgrade_requests').doc(requestId).update({
        'status': 'denied',
        'adminId': adminId,
        'adminName': adminName,
        'processedAt': Timestamp.fromDate(DateTime.now()),
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has a pending upgrade request
  Future<bool> hasPendingUpgradeRequest(String userId) async {
    try {
      final requests = await _firestore
          .collection('upgrade_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return requests.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update user fields by userId
  Future<void> updateUser(String userId, Map<String, dynamic> data, {
    String? performedBy,
    String? performedByName,
  }) async {
    final ActivityLogService _activityLogService = ActivityLogService();
    
    try {
      // Get the user data BEFORE updating to capture old values for logging
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final targetUserName = userData?['name'] ?? 'Unknown User';
      
      // Capture old values for logging before updating
      String? oldRole;
      if (data.containsKey('userRole')) {
        oldRole = userData?['userRole'];
      }
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update(data);
      
      // Log the activity if admin info is provided
      if (performedBy != null && performedByName != null) {
        // Determine what type of action was performed
        String action = 'user_edited';
        Map<String, dynamic>? details;
        
        if (data.containsKey('isModerator')) {
          action = data['isModerator'] ? 'moderator_granted' : 'moderator_removed';
        } else if (data.containsKey('userRole')) {
          action = 'role_changed';
          details = {
            'newRole': data['userRole'],
            'oldRole': oldRole ?? 'unknown',
          };
        } else if (data.containsKey('status')) {
          if (data['status'] == 'approved') {
            action = 'user_approved';
          }
        }
        
        await _activityLogService.logActivity(
          action: action,
          performedBy: performedBy,
          performedByName: performedByName,
          targetUserId: userId,
          targetUserName: targetUserName,
          details: details,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Private helper method: Delete all user data from Firestore
  // Used by both user self-deletion and admin deletion
  Future<void> _deleteUserData(String userId) async {
    try {
      debugPrint('Starting data deletion for user: $userId');
      
      // 1. Get all user's portraits to delete images from Storage
      final portraitsSnapshot = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('Found ${portraitsSnapshot.docs.length} portraits to delete');
      
      // 2. Delete portrait images from Firebase Storage
      // Note: We'll delete Firestore docs in batch, but Storage deletions need individual calls
      for (var doc in portraitsSnapshot.docs) {
        try {
          final data = doc.data();
          final imageUrl = data['imageUrl'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Storage deletion will be handled by portrait_service
            // For now, we'll just mark it for deletion
            debugPrint('Portrait image will be cleaned up: ${doc.id}');
          }
        } catch (e) {
          debugPrint('Error processing portrait ${doc.id}: $e');
          // Continue even if one portrait fails
        }
      }
      
      // 3. Create a batch for Firestore deletions
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      
      // Delete all portrait documents
      for (var doc in portraitsSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        
        // Firestore batch limit is 500 operations
        if (batchCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          debugPrint('Committed batch, continuing...');
        }
      }
      
      // 4. Get all weekly sessions to remove user's submissions and votes
      final sessionsSnapshot = await _firestore
          .collection('weekly_sessions')
          .get();
      
      debugPrint('Processing ${sessionsSnapshot.docs.length} weekly sessions');
      
      for (var sessionDoc in sessionsSnapshot.docs) {
        // Get submissions subcollection
        final submissionsSnapshot = await sessionDoc.reference
            .collection('submissions')
            .where('userId', isEqualTo: userId)
            .get();
        
        // Delete user's submissions
        for (var subDoc in submissionsSnapshot.docs) {
          batch.delete(subDoc.reference);
          batchCount++;
          
          if (batchCount >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
            debugPrint('Committed batch, continuing...');
          }
        }
        
        // Remove user's votes from other submissions
        final allSubmissionsSnapshot = await sessionDoc.reference
            .collection('submissions')
            .get();
        
        for (var subDoc in allSubmissionsSnapshot.docs) {
          final subData = subDoc.data();
          bool hasUserVote = false;
          
          // Check all vote categories
          for (var category in ['votes1st', 'votes2nd', 'votes3rd', 'votesMostFun']) {
            final votes = subData[category] as List<dynamic>?;
            if (votes != null && votes.contains(userId)) {
              hasUserVote = true;
              break;
            }
          }
          
          if (hasUserVote) {
            // Remove userId from all vote arrays
            batch.update(subDoc.reference, {
              'votes1st': FieldValue.arrayRemove([userId]),
              'votes2nd': FieldValue.arrayRemove([userId]),
              'votes3rd': FieldValue.arrayRemove([userId]),
              'votesMostFun': FieldValue.arrayRemove([userId]),
            });
            batchCount++;
            
            if (batchCount >= 400) {
              await batch.commit();
              batch = _firestore.batch();
              batchCount = 0;
              debugPrint('Committed batch, continuing...');
            }
          }
        }
      }
      
      // 5. Delete activity logs
      final activityLogsSnapshot = await _firestore
          .collection('activity_logs')
          .where('performedBy', isEqualTo: userId)
          .get();
      
      for (var doc in activityLogsSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        
        if (batchCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          debugPrint('Committed batch, continuing...');
        }
      }
      
      // 6. Delete upgrade requests (if any)
      final upgradeRequestsSnapshot = await _firestore
          .collection('upgrade_requests')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in upgradeRequestsSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        
        if (batchCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          debugPrint('Committed batch, continuing...');
        }
      }
      
      // 7. Delete user document
      batch.delete(_firestore.collection('users').doc(userId));
      batchCount++;
      
      // 8. Commit final batch
      await batch.commit();
      debugPrint('Data deletion completed successfully for user: $userId');
      
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  // Delete user account and all associated data (for user self-deletion)
  // This is the public method called from Settings screen
  // Note: Firebase Auth deletion is handled separately in AuthService
  Future<void> deleteUserAccount(String userId) async {
    await _deleteUserData(userId);
  }
} 
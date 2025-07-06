import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/upgrade_request_model.dart';

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
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
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

  // Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
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
  Future<void> approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'approved',
      });
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
      print('=== UPGRADE REQUEST DEBUG ===');
      print('Attempting to create upgrade request for user: $userId');
      print('User email: $userEmail');
      print('User name: $userName');
      
      // Check if user already has a pending request
      final existingRequests = await _firestore
          .collection('upgrade_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${existingRequests.docs.length} existing pending requests');

      if (existingRequests.docs.isNotEmpty) {
        print('User already has a pending request, throwing exception');
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

      print('Creating upgrade request document...');
      final docRef = await _firestore.collection('upgrade_requests').add(request.toMap());
      print('Upgrade request created successfully with ID: ${docRef.id}');

      // Send notification to admins
      print('Sending notification to admins...');
      await _sendUpgradeRequestNotificationToAdmins(userId, userName);
      print('Notification sent successfully');
      print('=== UPGRADE REQUEST COMPLETE ===');
    } catch (e) {
      print('=== UPGRADE REQUEST ERROR ===');
      print('Error creating upgrade request: $e');
      print('Error type: ${e.runtimeType}');
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
      print('Error sending admin notifications: $e');
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
        
        // Update the user's role to artist
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'userRole': 'artist',
        });
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
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update(data);
  }
} 
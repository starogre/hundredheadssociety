import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
} 
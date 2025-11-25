import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Block a user
  Future<void> blockUser({
    required String blockedBy,
    required String blockedUser,
  }) async {
    try {
      // Create a compound document ID to ensure uniqueness
      final blockId = '${blockedBy}_$blockedUser';
      
      debugPrint('📝 BlockService: Creating block document with ID: $blockId');
      debugPrint('📝 BlockService: Data - blockedBy: $blockedBy, blockedUser: $blockedUser');
      
      await _firestore.collection('blocks').doc(blockId).set({
        'blockedBy': blockedBy,
        'blockedUser': blockedUser,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ BlockService: Successfully created block document');
      debugPrint('✅ User $blockedUser blocked by $blockedBy');
    } catch (e) {
      debugPrint('❌ BlockService ERROR: $e');
      debugPrint('❌ BlockService ERROR TYPE: ${e.runtimeType}');
      debugPrint('❌ Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  Future<void> unblockUser({
    required String blockedBy,
    required String blockedUser,
  }) async {
    try {
      final blockId = '${blockedBy}_$blockedUser';
      await _firestore.collection('blocks').doc(blockId).delete();
      
      debugPrint('User $blockedUser unblocked by $blockedBy');
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if currentUser has blocked targetUser
  Future<bool> hasBlocked({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final blockId = '${currentUserId}_$targetUserId';
      final doc = await _firestore.collection('blocks').doc(blockId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Check if currentUser is blocked by targetUser
  Future<bool> isBlockedBy({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final blockId = '${targetUserId}_$currentUserId';
      final doc = await _firestore.collection('blocks').doc(blockId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if blocked by user: $e');
      return false;
    }
  }

  // Get all users blocked by currentUser
  Stream<List<String>> getBlockedUsers(String currentUserId) {
    return _firestore
        .collection('blocks')
        .where('blockedBy', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['blockedUser'] as String).toList();
    });
  }

  // Get all users who have blocked currentUser
  Stream<List<String>> getBlockedByUsers(String currentUserId) {
    return _firestore
        .collection('blocks')
        .where('blockedUser', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['blockedBy'] as String).toList();
    });
  }

  // Check if there's any block relationship between two users (either direction)
  Future<Map<String, bool>> checkBlockStatus({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final hasBlockedUser = await hasBlocked(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
      
      final isBlockedByUser = await isBlockedBy(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
      
      return {
        'hasBlocked': hasBlockedUser,
        'isBlockedBy': isBlockedByUser,
      };
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return {
        'hasBlocked': false,
        'isBlockedBy': false,
      };
    }
  }
}


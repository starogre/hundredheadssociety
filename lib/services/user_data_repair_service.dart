import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/portrait_model.dart';

/// Service for repairing user data inconsistencies
/// This service provides methods to fix data issues that can occur
/// when user documents are overwritten or corrupted
class UserDataRepairService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Repair user data by rebuilding portraitIds array and updating counts
  /// Returns a summary of what was repaired
  Future<UserDataRepairResult> repairUserData({
    required String userId,
    bool restoreAdmin = false,
    bool restoreModerator = false,
    String? correctName,
  }) async {
    try {
      print('🔧 Starting user data repair for user: $userId');
      
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }
      
      final userData = userDoc.data()!;
      final currentPortraitIds = List<String>.from(userData['portraitIds'] ?? []);
      final currentPortraitsCompleted = userData['portraitsCompleted'] ?? 0;
      
      print('📊 Current user data:');
      print('   - Name: ${userData['name']}');
      print('   - Portraits Completed: $currentPortraitsCompleted');
      print('   - Portrait IDs: ${currentPortraitIds.length} items');
      print('   - Is Admin: ${userData['isAdmin']}');
      print('   - Is Moderator: ${userData['isModerator']}');
      
      // Find all portraits for this user
      final portraitsQuery = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .orderBy('weekNumber')
          .get();
      
      final portraits = portraitsQuery.docs;
      print('🔍 Found ${portraits.length} portraits in database');
      
      if (portraits.isEmpty) {
        return UserDataRepairResult(
          success: true,
          message: 'No portraits found - nothing to repair',
          portraitsFound: 0,
          portraitsRepaired: 0,
          adminRestored: false,
          moderatorRestored: false,
          nameUpdated: false,
        );
      }
      
      // Extract portrait IDs and validate data
      final actualPortraitIds = portraits.map((doc) => doc.id).toList();
      final portraitData = portraits.map((doc) => doc.data()).toList();
      
      // Check for data inconsistencies
      final hasInconsistencies = 
          currentPortraitIds.length != actualPortraitIds.length ||
          currentPortraitsCompleted != portraits.length ||
          !_arraysEqual(currentPortraitIds, actualPortraitIds);
      
      print('🔍 Data consistency check:');
      print('   - Expected portrait IDs: ${actualPortraitIds.length}');
      print('   - Actual portrait IDs: ${currentPortraitIds.length}');
      print('   - Expected portraits completed: ${portraits.length}');
      print('   - Actual portraits completed: $currentPortraitsCompleted');
      print('   - Has inconsistencies: $hasInconsistencies');
      
      // Prepare updates
      final updates = <String, dynamic>{};
      bool needsUpdate = false;
      
      // Fix portrait data if needed
      if (hasInconsistencies) {
        updates['portraitIds'] = actualPortraitIds;
        updates['portraitsCompleted'] = portraits.length;
        needsUpdate = true;
        print('🔧 Will fix portrait data inconsistencies');
      }
      
      // Add privilege restoration if requested
      if (restoreAdmin && !(userData['isAdmin'] ?? false)) {
        updates['isAdmin'] = true;
        needsUpdate = true;
        print('🔑 Will restore admin privileges');
      }
      
      if (restoreModerator && !(userData['isModerator'] ?? false)) {
        updates['isModerator'] = true;
        needsUpdate = true;
        print('👮 Will restore moderator privileges');
      }
      
      // Add name correction if provided
      if (correctName != null && correctName.isNotEmpty && userData['name'] != correctName) {
        updates['name'] = correctName;
        needsUpdate = true;
        print('📝 Will update name to: $correctName');
      }
      
      if (!needsUpdate) {
        return UserDataRepairResult(
          success: true,
          message: 'No repairs needed - data is already consistent',
          portraitsFound: portraits.length,
          portraitsRepaired: 0,
          adminRestored: false,
          moderatorRestored: false,
          nameUpdated: false,
        );
      }
      
      // Apply updates
      print('🔄 Applying updates...');
      await _firestore.collection('users').doc(userId).update(updates);
      
      // Verify the changes
      final updatedDoc = await _firestore.collection('users').doc(userId).get();
      final updatedData = updatedDoc.data()!;
      
      print('✅ Updates applied successfully!');
      print('📊 Updated data:');
      print('   - Name: ${updatedData['name']}');
      print('   - Portraits Completed: ${updatedData['portraitsCompleted']}');
      print('   - Portrait IDs: ${updatedData['portraitIds']?.length ?? 0} items');
      print('   - Is Admin: ${updatedData['isAdmin']}');
      print('   - Is Moderator: ${updatedData['isModerator']}');
      
      return UserDataRepairResult(
        success: true,
        message: 'User data repair completed successfully',
        portraitsFound: portraits.length,
        portraitsRepaired: hasInconsistencies ? portraits.length : 0,
        adminRestored: restoreAdmin && !(userData['isAdmin'] ?? false),
        moderatorRestored: restoreModerator && !(userData['isModerator'] ?? false),
        nameUpdated: correctName != null && correctName.isNotEmpty && userData['name'] != correctName,
      );
      
    } catch (e) {
      print('❌ Error during user data repair: $e');
      return UserDataRepairResult(
        success: false,
        message: 'Repair failed: $e',
        portraitsFound: 0,
        portraitsRepaired: 0,
        adminRestored: false,
        moderatorRestored: false,
        nameUpdated: false,
      );
    }
  }
  
  /// Repair user data by email address
  Future<UserDataRepairResult> repairUserDataByEmail({
    required String email,
    bool restoreAdmin = false,
    bool restoreModerator = false,
    String? correctName,
  }) async {
    try {
      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return UserDataRepairResult(
          success: false,
          message: 'No user found with email: $email',
          portraitsFound: 0,
          portraitsRepaired: 0,
          adminRestored: false,
          moderatorRestored: false,
          nameUpdated: false,
        );
      }
      
      final userId = userQuery.docs.first.id;
      return await repairUserData(
        userId: userId,
        restoreAdmin: restoreAdmin,
        restoreModerator: restoreModerator,
        correctName: correctName,
      );
      
    } catch (e) {
      return UserDataRepairResult(
        success: false,
        message: 'Failed to find user by email: $e',
        portraitsFound: 0,
        portraitsRepaired: 0,
        adminRestored: false,
        moderatorRestored: false,
        nameUpdated: false,
      );
    }
  }
  
  /// Check if user data has inconsistencies
  Future<UserDataConsistencyCheck> checkUserDataConsistency(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return UserDataConsistencyCheck(
          hasIssues: true,
          issues: ['User document not found'],
          portraitCountMismatch: false,
          portraitIdsMismatch: false,
          totalPortraits: 0,
          userPortraitCount: 0,
          userPortraitIds: 0,
        );
      }
      
      final userData = userDoc.data()!;
      final userPortraitIds = List<String>.from(userData['portraitIds'] ?? []);
      final userPortraitCount = userData['portraitsCompleted'] ?? 0;
      
      // Get actual portraits
      final portraitsQuery = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .get();
      
      final actualPortraitCount = portraitsQuery.docs.length;
      final actualPortraitIds = portraitsQuery.docs.map((doc) => doc.id).toList();
      
      // Check for issues
      final issues = <String>[];
      bool portraitCountMismatch = false;
      bool portraitIdsMismatch = false;
      
      if (userPortraitCount != actualPortraitCount) {
        issues.add('Portrait count mismatch: user has $userPortraitCount, but $actualPortraitCount portraits exist');
        portraitCountMismatch = true;
      }
      
      if (userPortraitIds.length != actualPortraitIds.length) {
        issues.add('Portrait IDs array length mismatch: user has ${userPortraitIds.length}, but $actualPortraitCount portraits exist');
        portraitIdsMismatch = true;
      }
      
      if (!_arraysEqual(userPortraitIds, actualPortraitIds)) {
        issues.add('Portrait IDs array content mismatch: arrays contain different IDs');
        portraitIdsMismatch = true;
      }
      
      return UserDataConsistencyCheck(
        hasIssues: issues.isNotEmpty,
        issues: issues,
        portraitCountMismatch: portraitCountMismatch,
        portraitIdsMismatch: portraitIdsMismatch,
        totalPortraits: actualPortraitCount,
        userPortraitCount: userPortraitCount,
        userPortraitIds: userPortraitIds.length,
      );
      
    } catch (e) {
      return UserDataConsistencyCheck(
        hasIssues: true,
        issues: ['Error checking consistency: $e'],
        portraitCountMismatch: false,
        portraitIdsMismatch: false,
        totalPortraits: 0,
        userPortraitCount: 0,
        userPortraitIds: 0,
      );
    }
  }
  
  /// Helper method to compare two arrays
  bool _arraysEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Result of a user data repair operation
class UserDataRepairResult {
  final bool success;
  final String message;
  final int portraitsFound;
  final int portraitsRepaired;
  final bool adminRestored;
  final bool moderatorRestored;
  final bool nameUpdated;
  
  UserDataRepairResult({
    required this.success,
    required this.message,
    required this.portraitsFound,
    required this.portraitsRepaired,
    required this.adminRestored,
    required this.moderatorRestored,
    required this.nameUpdated,
  });
  
  @override
  String toString() {
    return 'UserDataRepairResult(success: $success, message: $message, '
           'portraitsFound: $portraitsFound, portraitsRepaired: $portraitsRepaired, '
           'adminRestored: $adminRestored, moderatorRestored: $moderatorRestored, '
           'nameUpdated: $nameUpdated)';
  }
}

/// Result of a user data consistency check
class UserDataConsistencyCheck {
  final bool hasIssues;
  final List<String> issues;
  final bool portraitCountMismatch;
  final bool portraitIdsMismatch;
  final int totalPortraits;
  final int userPortraitCount;
  final int userPortraitIds;
  
  UserDataConsistencyCheck({
    required this.hasIssues,
    required this.issues,
    required this.portraitCountMismatch,
    required this.portraitIdsMismatch,
    required this.totalPortraits,
    required this.userPortraitCount,
    required this.userPortraitIds,
  });
  
  @override
  String toString() {
    return 'UserDataConsistencyCheck(hasIssues: $hasIssues, issues: $issues, '
           'portraitCountMismatch: $portraitCountMismatch, portraitIdsMismatch: $portraitIdsMismatch, '
           'totalPortraits: $totalPortraits, userPortraitCount: $userPortraitCount, '
           'userPortraitIds: $userPortraitIds)';
  }
}

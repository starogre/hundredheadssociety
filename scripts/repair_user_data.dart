import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script to repair user data inconsistencies
/// This script will:
/// 1. Find all portraits for a user
/// 2. Rebuild the portraitIds array
/// 3. Update the portraitsCompleted count
/// 4. Optionally restore admin/moderator privileges
void main() async {
  print('🔧 User Data Repair Script');
  print('==========================');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  // Configuration - UPDATE THESE VALUES
  const String userEmail = 'jonshoob@gmail.com';
  const bool restoreAdmin = true;
  const bool restoreModerator = true;
  const String correctName = 'Jon Schubbe'; // Update with your actual name
  
  try {
    print('🔍 Looking for user with email: $userEmail');
    
    // Find user by email
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();
    
    if (userQuery.docs.isEmpty) {
      print('❌ No user found with email: $userEmail');
      return;
    }
    
    final userDoc = userQuery.docs.first;
    final userId = userDoc.id;
    final userData = userDoc.data();
    
    print('✅ Found user: ${userData['name']} (ID: $userId)');
    print('📊 Current data:');
    print('   - Name: ${userData['name']}');
    print('   - Portraits Completed: ${userData['portraitsCompleted']}');
    print('   - Portrait IDs: ${userData['portraitIds']?.length ?? 0} items');
    print('   - Is Admin: ${userData['isAdmin']}');
    print('   - Is Moderator: ${userData['isModerator']}');
    
    // Find all portraits for this user
    print('\n🔍 Finding all portraits for user...');
    final portraitsQuery = await firestore
        .collection('portraits')
        .where('userId', isEqualTo: userId)
        .orderBy('weekNumber')
        .get();
    
    final portraits = portraitsQuery.docs;
    print('✅ Found ${portraits.length} portraits');
    
    if (portraits.isEmpty) {
      print('ℹ️  No portraits found. Nothing to repair.');
      return;
    }
    
    // Extract portrait IDs and validate data
    final portraitIds = portraits.map((doc) => doc.id).toList();
    final portraitData = portraits.map((doc) => doc.data()).toList();
    
    print('\n📋 Portrait Details:');
    for (int i = 0; i < portraits.length; i++) {
      final data = portraitData[i];
      print('   Week ${data['weekNumber']}: ${data['title']} (ID: ${portraitIds[i]})');
    }
    
    // Validate week numbers are sequential
    final weekNumbers = portraitData.map((data) => data['weekNumber'] as int).toList();
    final expectedWeeks = List.generate(portraits.length, (index) => index + 1);
    final weekNumbersMatch = weekNumbers.every((week) => expectedWeeks.contains(week));
    
    if (!weekNumbersMatch) {
      print('⚠️  Warning: Week numbers are not sequential!');
      print('   Found weeks: $weekNumbers');
      print('   Expected weeks: $expectedWeeks');
    }
    
    // Prepare updates
    final updates = <String, dynamic>{
      'portraitIds': portraitIds,
      'portraitsCompleted': portraits.length,
    };
    
    // Add privilege restoration if requested
    if (restoreAdmin) {
      updates['isAdmin'] = true;
      print('🔑 Will restore admin privileges');
    }
    
    if (restoreModerator) {
      updates['isModerator'] = true;
      print('👮 Will restore moderator privileges');
    }
    
    // Add name correction if provided
    if (correctName.isNotEmpty && userData['name'] != correctName) {
      updates['name'] = correctName;
      print('📝 Will update name to: $correctName');
    }
    
    // Show what will be updated
    print('\n📝 Updates to be applied:');
    updates.forEach((key, value) {
      if (key == 'portraitIds') {
        print('   - $key: ${(value as List).length} items');
      } else {
        print('   - $key: $value');
      }
    });
    
    // Confirm before proceeding
    print('\n❓ Do you want to proceed with these updates? (y/N)');
    final confirmation = stdin.readLineSync()?.toLowerCase();
    
    if (confirmation != 'y' && confirmation != 'yes') {
      print('❌ Operation cancelled.');
      return;
    }
    
    // Apply updates
    print('\n🔄 Applying updates...');
    await firestore.collection('users').doc(userId).update(updates);
    
    print('✅ Updates applied successfully!');
    
    // Verify the changes
    print('\n🔍 Verifying changes...');
    final updatedDoc = await firestore.collection('users').doc(userId).get();
    final updatedData = updatedDoc.data()!;
    
    print('📊 Updated data:');
    print('   - Name: ${updatedData['name']}');
    print('   - Portraits Completed: ${updatedData['portraitsCompleted']}');
    print('   - Portrait IDs: ${updatedData['portraitIds']?.length ?? 0} items');
    print('   - Is Admin: ${updatedData['isAdmin']}');
    print('   - Is Moderator: ${updatedData['isModerator']}');
    
    // Final verification - check if portraits still show up
    print('\n🔍 Final verification - checking portrait display...');
    final verifyPortraits = await firestore
        .collection('portraits')
        .where('userId', isEqualTo: userId)
        .get();
    
    print('✅ Verification complete: ${verifyPortraits.docs.length} portraits found');
    
    print('\n🎉 User data repair completed successfully!');
    print('   Your portraits should now display correctly in your profile.');
    print('   Admin/moderator privileges have been restored.');
    print('   Portrait count and IDs are now synchronized.');
    
  } catch (e) {
    print('❌ Error during repair: $e');
    print('   Please check your Firebase configuration and try again.');
  }
  
  // Close the app
  exit(0);
}

/// Helper function to validate Firebase configuration
void validateFirebaseConfig() {
  print('🔧 Validating Firebase configuration...');
  
  // Check if firebase_options.dart exists
  final firebaseOptionsFile = File('lib/firebase_options.dart');
  if (!firebaseOptionsFile.existsSync()) {
    print('❌ firebase_options.dart not found!');
    print('   Please run: flutterfire configure');
    exit(1);
  }
  
  print('✅ Firebase configuration looks good');
}

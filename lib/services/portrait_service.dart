import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';

class PortraitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Upload portrait image to Firebase Storage
  Future<String> uploadPortraitImage(File imageFile, String userId) async {
    try {
      debugPrint('Starting image upload to Firebase Storage');
      String fileName = 'portraits/$userId/${_uuid.v4()}.jpg';
              debugPrint('Generated filename: $fileName');
      Reference ref = _storage.ref().child(fileName);
      
              debugPrint('Starting upload task');
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

              debugPrint('Waiting for upload to complete');
      TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          debugPrint('Upload timed out after 2 minutes');
          throw TimeoutException('Upload timed out after 2 minutes');
        },
      );
      
      if (snapshot.state == TaskState.error) {
        debugPrint('Upload failed with error state');
        throw Exception('Upload failed: ${snapshot.state}');
      }

              debugPrint('Upload complete, getting download URL');
      String downloadUrl = await snapshot.ref.getDownloadURL();
              debugPrint('Got download URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
              debugPrint('Firebase error in uploadPortraitImage: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
              debugPrint('Error in uploadPortraitImage: $e');
      rethrow;
    }
  }

  // Add new portrait
  Future<void> addPortrait({
    required String userId,
    required String imageUrl,
    required String title,
    String? description,
    int? weekNumber,
    String? modelName,
  }) async {
    try {
      debugPrint('Getting user document for week number');
      // Get user's current portrait count to determine week number
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
              debugPrint('Got user document');
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      
      int targetWeekNumber;
      if (weekNumber != null) {
        // Use provided week number
        targetWeekNumber = weekNumber;
                  debugPrint('Using provided week number: $targetWeekNumber');
      } else {
        // Calculate next week number
        targetWeekNumber = user.portraitsCompleted + 1;
                  debugPrint('Calculated week number: $targetWeekNumber');
      }
      
      // If using a custom week number, we need to shift existing portraits
      if (weekNumber != null && weekNumber <= user.portraitsCompleted) {
        await _shiftWeeksForInsertion(userId, weekNumber);
      }
      
      // Create portrait document
              debugPrint('Creating portrait document');
      DocumentReference portraitRef = await _firestore.collection('portraits').add({
        'userId': userId,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'weekNumber': targetWeekNumber,
        'modelName': modelName,
      });
              debugPrint('Created portrait document with ID: ${portraitRef.id}');

      // Update user's portrait count and add portrait ID to user's list
              debugPrint('Updating user document');
      await _firestore.collection('users').doc(userId).update({
        'portraitsCompleted': FieldValue.increment(1),
        'portraitIds': FieldValue.arrayUnion([portraitRef.id]),
      });
              debugPrint('User document updated successfully');
    } catch (e) {
              debugPrint('Error in addPortrait: $e');
      rethrow;
    }
  }

  // Get user's portraits
  Stream<List<PortraitModel>> getUserPortraits(String userId) {
    return _firestore
        .collection('portraits')
        .where('userId', isEqualTo: userId)
        .orderBy('weekNumber')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PortraitModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get user's portraits in reverse order (newest first) for profile view
  Stream<List<PortraitModel>> getUserPortraitsReversed(String userId) {
    return _firestore
        .collection('portraits')
        .where('userId', isEqualTo: userId)
        .orderBy('weekNumber', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PortraitModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all portraits for community view
  Stream<List<PortraitModel>> getAllPortraits() {
    return _firestore
        .collection('portraits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PortraitModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get portrait by ID
  Future<PortraitModel?> getPortraitById(String portraitId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('portraits').doc(portraitId).get();
      if (doc.exists) {
        return PortraitModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Delete portrait
  Future<void> deletePortrait(String portraitId, String userId) async {
    try {
      // Get portrait data first
      PortraitModel? portrait = await getPortraitById(portraitId);
      if (portrait == null) return;

      // Delete from Firestore
      await _firestore.collection('portraits').doc(portraitId).delete();

      // Delete from Storage
      try {
        Reference ref = _storage.refFromURL(portrait.imageUrl);
        await ref.delete();
      } catch (e) {
        // Image might already be deleted or URL might be invalid
        debugPrint('Error deleting image from storage: $e');
      }

      // Update user's portrait count and remove portrait ID from user's list
      await _firestore.collection('users').doc(userId).update({
        'portraitsCompleted': FieldValue.increment(-1),
        'portraitIds': FieldValue.arrayRemove([portraitId]),
      });

      // Shift all portraits with higher week numbers back by one
      await _shiftWeeksAfterDeletion(userId, portrait.weekNumber);
    } catch (e) {
      rethrow;
    }
  }

  // Shift weeks after deletion to fill gaps
  Future<void> _shiftWeeksAfterDeletion(String userId, int deletedWeekNumber) async {
    try {
      // Get all portraits with week numbers higher than the deleted one
      QuerySnapshot higherPortraits = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .where('weekNumber', isGreaterThan: deletedWeekNumber)
          .orderBy('weekNumber')
          .get();

      // Update each portrait to shift its week number back by one
      for (QueryDocumentSnapshot doc in higherPortraits.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentWeek = data['weekNumber'] as int;
        await _firestore.collection('portraits').doc(doc.id).update({
          'weekNumber': currentWeek - 1,
        });
      }
    } catch (e) {
              debugPrint('Error shifting weeks after deletion: $e');
      rethrow;
    }
  }

  // Shift weeks for insertion to make room for new portrait
  Future<void> _shiftWeeksForInsertion(String userId, int insertWeekNumber) async {
    try {
              debugPrint('Shifting weeks for insertion at week $insertWeekNumber');
      // Get all portraits with week numbers greater than or equal to the insert week
      QuerySnapshot existingPortraits = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .where('weekNumber', isGreaterThanOrEqualTo: insertWeekNumber)
          .orderBy('weekNumber', descending: false) // Process from lowest to highest
          .get();

              debugPrint('Found ${existingPortraits.docs.length} portraits to shift');

      // Update each portrait to shift its week number forward by one
      for (QueryDocumentSnapshot doc in existingPortraits.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentWeek = data['weekNumber'] as int;
        int newWeek = currentWeek + 1;
                    debugPrint('Shifting portrait ${doc.id} from week $currentWeek to week $newWeek');
        await _firestore.collection('portraits').doc(doc.id).update({
          'weekNumber': newWeek,
        });
              }
        debugPrint('Week shifting completed');
      } catch (e) {
        debugPrint('Error shifting weeks for insertion: $e');
      rethrow;
    }
  }

  // Fix week gaps by reordering portraits to fill missing weeks
  Future<void> fixWeekGaps(String userId) async {
    try {
              debugPrint('Fixing week gaps for user: $userId');
      
      // Get all user's portraits ordered by week number
      QuerySnapshot portraitsSnapshot = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .orderBy('weekNumber')
          .get();

      List<QueryDocumentSnapshot> portraits = portraitsSnapshot.docs;
              debugPrint('Found ${portraits.length} portraits');

      if (portraits.isEmpty) {
                  debugPrint('No portraits found, nothing to fix');
        return;
      }

      // Check for gaps and fix them
      int expectedWeek = 1;
      List<Map<String, dynamic>> updates = [];

      for (int i = 0; i < portraits.length; i++) {
        QueryDocumentSnapshot doc = portraits[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentWeek = data['weekNumber'] as int;

        if (currentWeek != expectedWeek) {
                      debugPrint('Gap detected: expected week $expectedWeek, found week $currentWeek');
          updates.add({
            'docId': doc.id,
            'newWeek': expectedWeek,
          });
        }
        expectedWeek++;
      }

      // Apply updates to fix gaps
      for (Map<String, dynamic> update in updates) {
        await _firestore.collection('portraits').doc(update['docId']).update({
          'weekNumber': update['newWeek'],
        });
                    debugPrint('Updated portrait ${update['docId']} to week ${update['newWeek']}');
      }

              debugPrint('Week gap fixing completed');
    } catch (e) {
              debugPrint('Error fixing week gaps: $e');
      rethrow;
    }
  }

  // Get next available week number for user
  Future<int> getNextWeekNumber(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      return user.portraitsCompleted + 1;
    } catch (e) {
      rethrow;
    }
  }

  // Update existing portrait
  Future<void> updatePortrait({
    required String portraitId,
    required String title,
    String? description,
    String? imageUrl,
    String? modelName,
    int? weekNumber,
  }) async {
    try {
              debugPrint('Updating portrait: $portraitId');
      
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // First, verify the portrait exists
        DocumentSnapshot portraitDoc = await transaction.get(
          _firestore.collection('portraits').doc(portraitId)
        );
        
        if (!portraitDoc.exists) {
          throw Exception('Portrait not found');
        }
        
        Map<String, dynamic> updates = {
          'title': title,
          'description': description,
        };
        
        if (imageUrl != null) {
          updates['imageUrl'] = imageUrl;
        }
        if (modelName != null) {
          updates['modelName'] = modelName;
        }
        if (weekNumber != null) {
          updates['weekNumber'] = weekNumber;
        }
        
        transaction.update(
          _firestore.collection('portraits').doc(portraitId),
          updates
        );
      });
      
              debugPrint('Portrait updated successfully');
    } catch (e) {
              debugPrint('Error in updatePortrait: $e');
      rethrow;
    }
  }

  // Shift weeks when a portrait's week number is changed
  Future<void> shiftWeeksForWeekChange(String userId, int oldWeek, int newWeek, String portraitId) async {
    try {
              debugPrint('Shifting weeks for week change: $oldWeek -> $newWeek for portrait $portraitId');
      
      if (oldWeek == newWeek) {
                  debugPrint('No week change, nothing to shift');
        return;
      }

      // Get all user's portraits
      QuerySnapshot allPortraits = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .get();

      // Create a map of current week numbers to document IDs (excluding the edited portrait)
      Map<int, String> weekToDocId = {};
      for (QueryDocumentSnapshot doc in allPortraits.docs) {
        if (doc.id != portraitId) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int week = data['weekNumber'] as int;
          weekToDocId[week] = doc.id;
        }
      }

      List<Map<String, dynamic>> updates = [];

      if (newWeek < oldWeek) {
        // Moving to an earlier week - shift portraits in the range [newWeek, oldWeek-1] forward by 1
        for (int week = newWeek; week < oldWeek; week++) {
          if (weekToDocId.containsKey(week)) {
            updates.add({
              'docId': weekToDocId[week]!,
              'newWeek': week + 1,
            });
          }
        }
      } else {
        // Moving to a later week - shift portraits in the range [oldWeek+1, newWeek] backward by 1
        for (int week = oldWeek + 1; week <= newWeek; week++) {
          if (weekToDocId.containsKey(week)) {
            updates.add({
              'docId': weekToDocId[week]!,
              'newWeek': week - 1,
            });
          }
        }
      }

              debugPrint('Found ${updates.length} portraits to update');

      // Apply all updates
      for (Map<String, dynamic> update in updates) {
                  debugPrint('Updating portrait ${update['docId']} to week ${update['newWeek']}');
        await _firestore.collection('portraits').doc(update['docId']).update({
          'weekNumber': update['newWeek'],
        });
      }

              debugPrint('Week shifting completed');
    } catch (e) {
              debugPrint('Error shifting weeks for week change: $e');
      rethrow;
    }
  }

  // Renumber all portraits sequentially starting from week 1
  Future<void> renumberPortraitsSequentially(String userId) async {
    try {
              debugPrint('Renumbering portraits sequentially for user: $userId');
      
      // Get all user's portraits ordered by current week number
      QuerySnapshot portraitsSnapshot = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .orderBy('weekNumber')
          .get();

      List<QueryDocumentSnapshot> portraits = portraitsSnapshot.docs;
              debugPrint('Found ${portraits.length} portraits to renumber');

      if (portraits.isEmpty) {
                  debugPrint('No portraits found, nothing to renumber');
        return;
      }

      // Renumber all portraits sequentially starting from 1
      for (int i = 0; i < portraits.length; i++) {
        QueryDocumentSnapshot doc = portraits[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentWeek = data['weekNumber'] as int;
        int newWeek = i + 1;

        if (currentWeek != newWeek) {
          debugPrint('Renumbering portrait ${doc.id} from week $currentWeek to week $newWeek');
          await _firestore.collection('portraits').doc(doc.id).update({
            'weekNumber': newWeek,
          });
        }
      }

              debugPrint('Sequential renumbering completed');
    } catch (e) {
              debugPrint('Error renumbering portraits sequentially: $e');
      rethrow;
    }
  }
} 
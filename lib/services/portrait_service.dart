import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
      print('Starting image upload to Firebase Storage');
      String fileName = 'portraits/$userId/${_uuid.v4()}.jpg';
      print('Generated filename: $fileName');
      Reference ref = _storage.ref().child(fileName);
      
      print('Starting upload task');
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      print('Waiting for upload to complete');
      TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          print('Upload timed out after 2 minutes');
          throw TimeoutException('Upload timed out after 2 minutes');
        },
      );
      
      if (snapshot.state == TaskState.error) {
        print('Upload failed with error state');
        throw Exception('Upload failed: ${snapshot.state}');
      }

      print('Upload complete, getting download URL');
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Got download URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error in uploadPortraitImage: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error in uploadPortraitImage: $e');
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
      print('Getting user document for week number');
      // Get user's current portrait count to determine week number
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      print('Got user document');
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      
      int targetWeekNumber;
      if (weekNumber != null) {
        // Use provided week number
        targetWeekNumber = weekNumber;
        print('Using provided week number: $targetWeekNumber');
      } else {
        // Calculate next week number
        targetWeekNumber = user.portraitsCompleted + 1;
        print('Calculated week number: $targetWeekNumber');
      }
      
      // If using a custom week number, we need to shift existing portraits
      if (weekNumber != null && weekNumber <= user.portraitsCompleted) {
        await _shiftWeeksForInsertion(userId, weekNumber);
      }
      
      // Create portrait document
      print('Creating portrait document');
      DocumentReference portraitRef = await _firestore.collection('portraits').add({
        'userId': userId,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'weekNumber': targetWeekNumber,
        'modelName': modelName,
      });
      print('Created portrait document with ID: ${portraitRef.id}');

      // Update user's portrait count and add portrait ID to user's list
      print('Updating user document');
      await _firestore.collection('users').doc(userId).update({
        'portraitsCompleted': FieldValue.increment(1),
        'portraitIds': FieldValue.arrayUnion([portraitRef.id]),
      });
      print('User document updated successfully');
    } catch (e) {
      print('Error in addPortrait: $e');
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
        print('Error deleting image from storage: $e');
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
      print('Error shifting weeks after deletion: $e');
      rethrow;
    }
  }

  // Shift weeks for insertion to make room for new portrait
  Future<void> _shiftWeeksForInsertion(String userId, int insertWeekNumber) async {
    try {
      print('Shifting weeks for insertion at week $insertWeekNumber');
      // Get all portraits with week numbers greater than or equal to the insert week
      QuerySnapshot existingPortraits = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .where('weekNumber', isGreaterThanOrEqualTo: insertWeekNumber)
          .orderBy('weekNumber', descending: false) // Process from lowest to highest
          .get();

      print('Found ${existingPortraits.docs.length} portraits to shift');

      // Update each portrait to shift its week number forward by one
      for (QueryDocumentSnapshot doc in existingPortraits.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentWeek = data['weekNumber'] as int;
        int newWeek = currentWeek + 1;
        print('Shifting portrait ${doc.id} from week $currentWeek to week $newWeek');
        await _firestore.collection('portraits').doc(doc.id).update({
          'weekNumber': newWeek,
        });
      }
      print('Week shifting completed');
    } catch (e) {
      print('Error shifting weeks for insertion: $e');
      rethrow;
    }
  }

  // Fix week gaps by reordering portraits to fill missing weeks
  Future<void> fixWeekGaps(String userId) async {
    try {
      print('Fixing week gaps for user: $userId');
      
      // Get all user's portraits ordered by week number
      QuerySnapshot portraitsSnapshot = await _firestore
          .collection('portraits')
          .where('userId', isEqualTo: userId)
          .orderBy('weekNumber')
          .get();

      List<QueryDocumentSnapshot> portraits = portraitsSnapshot.docs;
      print('Found ${portraits.length} portraits');

      if (portraits.isEmpty) {
        print('No portraits found, nothing to fix');
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
          print('Gap detected: expected week $expectedWeek, found week $currentWeek');
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
        print('Updated portrait ${update['docId']} to week ${update['newWeek']}');
      }

      print('Week gap fixing completed');
    } catch (e) {
      print('Error fixing week gaps: $e');
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
  }) async {
    try {
      print('Updating portrait: $portraitId');
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
      await _firestore.collection('portraits').doc(portraitId).update(updates);
      print('Portrait updated successfully');
    } catch (e) {
      print('Error in updatePortrait: $e');
      rethrow;
    }
  }
} 
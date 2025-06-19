import 'dart:io';
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
      String fileName = 'portraits/$userId/${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Add new portrait
  Future<void> addPortrait({
    required String userId,
    required String imageUrl,
    required String title,
    String? description,
  }) async {
    try {
      // Get user's current portrait count to determine week number
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
      
      int weekNumber = user.portraitsCompleted + 1;
      
      // Create portrait document
      DocumentReference portraitRef = await _firestore.collection('portraits').add({
        'userId': userId,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'weekNumber': weekNumber,
      });

      // Update user's portrait count and add portrait ID to user's list
      await _firestore.collection('users').doc(userId).update({
        'portraitsCompleted': FieldValue.increment(1),
        'portraitIds': FieldValue.arrayUnion([portraitRef.id]),
      });
    } catch (e) {
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
    } catch (e) {
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
} 
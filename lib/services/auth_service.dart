import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'activity_log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String userRole,
  }) async {
    try {
      print('Attempting to create user with email: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User created successfully: ${result.user?.uid}');

      // Send email verification
      if (result.user != null) {
        await result.user!.sendEmailVerification();
        print('Email verification sent to: $email');
      }

      // Create user document in Firestore
      if (result.user != null) {
        print('Creating user document in Firestore...');
        try {
          // Use the same raw operation approach
          final docRef = _firestore.collection('users').doc(result.user!.uid);
          
          // Determine status based on user role
          final status = userRole == 'art_appreciator' ? 'approved' : 'pending';
          
          final data = <String, dynamic>{
            'email': email,
            'name': name,
            'bio': null,
            'profileImageUrl': null,
            'createdAt': Timestamp.now(),
            'portraitIds': <String>[],
            'portraitsCompleted': 0,
            'isAdmin': false,
            'status': status, // Auto-approve art appreciators, keep artists pending
            'userRole': userRole,
            'isModerator': false,
            'awards': <String>[],
            'totalVotesCast': 0,
            'emailVerified': false, // Track email verification status
          };
          
          await docRef.set(data);
          print('User document created successfully');

          // Send notification to admins if this is a new artist signup
          if (userRole == 'artist') {
            await _sendNewArtistSignupNotification(result.user!.uid, name);
          }
        } catch (firestoreError) {
          print('Firestore error: $firestoreError');
          print('Firestore error type: ${firestoreError.runtimeType}');
          
          // Try minimal document creation
          try {
            print('Trying minimal document creation...');
            
            // Determine status based on user role
            final status = userRole == 'art_appreciator' ? 'approved' : 'pending';
            
            await _firestore.collection('users').doc(result.user!.uid).set({
              'email': email,
              'name': name,
              'status': status, // Auto-approve art appreciators, keep artists pending
              'userRole': userRole,
              'isModerator': false,
              'emailVerified': false, // Track email verification status
            });
            print('Minimal user document created');
          } catch (minimalError) {
            print('Minimal creation also failed: $minimalError');
            // Don't rethrow - we still want to return the UserCredential
            // The user document can be created later
          }
        }
      }

      return result;
    } catch (e) {
      print('Error in signUpWithEmailAndPassword: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      print('=== EMAIL VERIFICATION DEBUG ===');
      print('Current user: ${_auth.currentUser?.uid}');
      print('Current user email: ${_auth.currentUser?.email}');
      print('Email verified: ${_auth.currentUser?.emailVerified}');
      
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        print('Sending email verification...');
        await _auth.currentUser!.sendEmailVerification();
        print('Email verification sent successfully to: ${_auth.currentUser!.email}');
      } else {
        print('User is null or already verified');
      }
    } catch (e) {
      print('=== EMAIL VERIFICATION ERROR ===');
      print('Error sending email verification: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Check if user is verified
  bool isUserVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Error reloading user: $e');
      rethrow;
    }
  }

  // Update user email verification status and timestamp
  Future<void> updateUserEmailVerificationStatus(String userId, bool isVerified) async {
    final ActivityLogService _activityLogService = ActivityLogService();
    
    try {
      final data = <String, dynamic>{
        'emailVerified': isVerified,
      };
      
      // If verifying, also update the timestamp
      if (isVerified) {
        data['lastVerificationTimestamp'] = Timestamp.now();
      }
      
      await _firestore.collection('users').doc(userId).update(data);
      print('Updated email verification status for user $userId: $isVerified');
      
      // Log the email verification activity (but exclude admin verification on every login)
      if (isVerified) {
        // Get the user data to check if they're admin and log their name
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        final userName = userData?['name'] ?? 'Unknown User';
        final isAdmin = userData?['isAdmin'] ?? false;
        
        // Only log if this is NOT an admin user (to avoid spamming the log with admin login verifications)
        if (!isAdmin) {
          await _activityLogService.logActivity(
            action: 'user_signup',
            performedBy: userId, // The user themselves
            performedByName: userName,
            targetUserId: userId,
            targetUserName: userName,
          );
        } else {
          print('Skipping activity log for admin email verification to avoid spam');
        }
      }
    } catch (e) {
      print('Error updating email verification status: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Send notification to admins for new artist signup
  Future<void> _sendNewArtistSignupNotification(String userId, String userName) async {
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
          'type': 'new_artist_signup',
          'title': 'New Artist Registration',
          'message': '$userName has signed up as an artist',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'read': false,
          'data': {
            'newUserId': userId,
            'newUserName': userName,
            'action': 'view_approvals',
          },
        };

        batch.set(notificationRef, notification);
      }

      await batch.commit();
    } catch (e) {
      // Log error but don't fail the signup process
      print('Error sending admin notifications for new artist: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
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

  // Create user document in Firestore (fallback method)
  Future<void> createUserDocument({
    required String userId,
    required String email,
    required String name,
    String userRole = 'artist',
  }) async {
    try {
      print('Creating user document with raw operation...');
      
      // Try using a more direct approach
      final docRef = _firestore.collection('users').doc(userId);
      final data = <String, dynamic>{
        'email': email,
        'name': name,
        'bio': null,
        'profileImageUrl': null,
        'createdAt': Timestamp.now(),
        'portraitIds': <String>[],
        'portraitsCompleted': 0,
        'isAdmin': false,
        'status': 'approved',
        'userRole': userRole,
        'isModerator': false,
        'awards': <String>[],
        'totalVotesCast': 0,
      };
      
      await docRef.set(data);
      print('User document created successfully with raw operation');
    } catch (e) {
      print('Error creating user document: $e');
      print('Error type: ${e.runtimeType}');
      
      // Last resort: try without any complex types
      try {
        print('Trying minimal document creation...');
        await _firestore.collection('users').doc(userId).set({
          'email': email,
          'name': name,
          'status': 'approved',
          'userRole': userRole,
          'isModerator': false,
        });
        print('Minimal user document created');
      } catch (minimalError) {
        print('Minimal creation also failed: $minimalError');
        rethrow;
      }
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification for admin users (forces new verification on every login)
  Future<void> sendAdminEmailVerification() async {
    try {
      print('=== ADMIN EMAIL VERIFICATION DEBUG ===');
      print('Current user: ${_auth.currentUser?.uid}');
      print('Current user email: ${_auth.currentUser?.email}');
      print('Email verified: ${_auth.currentUser?.emailVerified}');
      
      if (_auth.currentUser != null) {
        print('Sending admin verification email...');
        await _auth.currentUser!.sendEmailVerification();
        print('Admin verification email sent successfully to: ${_auth.currentUser!.email}');
      } else {
        print('User is null');
      }
    } catch (e) {
      print('=== ADMIN EMAIL VERIFICATION ERROR ===');
      print('Error sending admin verification email: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }
} 
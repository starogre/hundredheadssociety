import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get currentUser => _currentUser;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Delay initialization to ensure Firebase is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[AuthProvider] Initializing...');
      _init();
    });
  }

  void _init() {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
      print('[AuthProvider] Setting up authStateChanges listener');
      _authService.authStateChanges.listen((User? user) {
        print('[AuthProvider] authStateChanges event: user=${user?.uid}');
        _currentUser = user;
        if (user != null) {
          print('[AuthProvider] User is logged in, loading user data...');
          _loadUserData();
        } else {
          print('[AuthProvider] User is logged out, clearing userData');
          _userData = null;
        }
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to listen to auth state changes: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        _userData = await _authService.getUserData(_currentUser!.uid);
        
        // If user data doesn't exist, create it (fallback for failed initial creation)
        if (_userData == null) {
          print('[AuthProvider] User document not found, creating fallback document...');
          try {
            await _authService.createUserDocument(
              userId: _currentUser!.uid,
              email: _currentUser!.email ?? '',
              name: _currentUser!.displayName ?? 'User',
            );
            print('[AuthProvider] Fallback user document created');
            
            // Try to load the data again
            _userData = await _authService.getUserData(_currentUser!.uid);
          } catch (fallbackError) {
            print('[AuthProvider] Fallback document creation failed: $fallbackError');
            _error = 'Failed to create user profile: $fallbackError';
          }
        } else {
          // For existing non-admin users, ensure they have emailVerified field set to true
          if (_userData!.emailVerified == false && _userData!.status == 'approved' && !_userData!.isAdmin) {
            print('[AuthProvider] Updating existing non-admin user to mark email as verified');
            try {
              await _authService.updateUserEmailVerificationStatus(_currentUser!.uid, true);
              // Reload user data to get updated values
              _userData = await _authService.getUserData(_currentUser!.uid);
            } catch (e) {
              print('[AuthProvider] Failed to update existing user email verification: $e');
            }
          }
        }
        
        // Check email verification status - only for new users (created after email verification was implemented)
        if (_userData != null && 
            _userData!.emailVerified == false && 
            _userData!.status == 'pending' && 
            !_authService.isUserVerified()) {
          print('[AuthProvider] New user email not verified');
          _error = 'Please verify your email address to continue.';
        }
        
        // For admin users, always require email verification on every login
        if (_userData != null && _userData!.isAdmin) {
          print('[AuthProvider] Admin user detected - checking verification timestamp');
          
          // Check if admin has verified their email since the last login
          final lastVerification = _userData!.lastVerificationTimestamp;
          final now = DateTime.now();
          
          // If no verification timestamp or verification is older than 24 hours, require re-verification
          if (lastVerification == null || now.difference(lastVerification).inHours > 24) {
            print('[AuthProvider] Admin user needs re-verification - sending new email');
            
            // Send a new verification email for admin users
            try {
              await _authService.sendAdminEmailVerification();
              print('[AuthProvider] New verification email sent to admin user');
            } catch (e) {
              print('[AuthProvider] Failed to send verification email to admin: $e');
            }
            
            // Don't set error here - let needsEmailVerification handle the routing
            print('[AuthProvider] Admin user needs verification - will be handled by routing');
          } else {
            print('[AuthProvider] Admin user recently verified - allowing access');
          }
        }
        
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load user data: $e';
        notifyListeners();
      }
    }
  }

  // Check if user needs email verification
  bool get needsEmailVerification {
    if (_currentUser == null || _userData == null) {
      print('[AuthProvider] needsEmailVerification: User or userData is null');
      return false;
    }
    
    print('[AuthProvider] needsEmailVerification check:');
    print('  - Is admin: ${_userData!.isAdmin}');
    print('  - User role: ${_userData!.userRole}');
    print('  - Email verified: ${_userData!.emailVerified}');
    print('  - Status: ${_userData!.status}');
    print('  - Firebase verified: ${_authService.isUserVerified()}');
    print('  - Last verification timestamp: ${_userData!.lastVerificationTimestamp}');
    
    // For regular users: check if they're new and haven't verified
    if (!_userData!.isAdmin) {
      // Art appreciators don't need approval, so they only need email verification if they're new
      if (_userData!.userRole == 'art_appreciator') {
        final needsVerification = _userData!.emailVerified == false && !_authService.isUserVerified();
        print('[AuthProvider] Art appreciator needs verification: $needsVerification');
        return needsVerification;
      }
      
      // Artists need both email verification and approval
      if (_userData!.userRole == 'artist') {
        final needsVerification = _userData!.emailVerified == false && 
               _userData!.status == 'pending' && 
               !_authService.isUserVerified();
        print('[AuthProvider] Artist needs verification: $needsVerification');
        return needsVerification;
      }
    }
    
    // For admin users: check if they need re-verification based on timestamp
    if (_userData!.isAdmin) {
      final lastVerification = _userData!.lastVerificationTimestamp;
      final now = DateTime.now();
      
      // Require re-verification if no timestamp or verification is older than 24 hours
      final needsVerification = lastVerification == null || now.difference(lastVerification).inHours > 24;
      print('[AuthProvider] Admin user needs verification: $needsVerification');
      print('  - Last verification: $lastVerification');
      print('  - Time difference: ${lastVerification != null ? now.difference(lastVerification).inHours : 'null'} hours');
      return needsVerification;
    }
    
    print('[AuthProvider] No verification needed');
    return false;
  }

  // Reload user data (useful after email verification)
  Future<void> reloadUserData() async {
    await _authService.reloadUser();
    await _loadUserData();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String userRole,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        userRole: userRole,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Sign up failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError(); // Clear any previous errors
    
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Sign in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userData = null;
    } catch (e) {
      _setError('Sign out failed: $e');
    }
    _setLoading(false);
  }

  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.uid,
        name: name,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );
      
      // Reload user data
      await _loadUserData();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
} 
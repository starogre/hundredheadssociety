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
        }
        
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load user data: $e';
        notifyListeners();
      }
    }
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
    _clearError();
    
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

  Future<void> reloadUserData() async {
    await _loadUserData();
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
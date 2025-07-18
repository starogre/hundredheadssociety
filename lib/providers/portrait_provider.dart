import 'dart:io';
import 'package:flutter/material.dart';
import '../services/portrait_service.dart';
import '../models/portrait_model.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PortraitProvider extends ChangeNotifier {
  final PortraitService _portraitService = PortraitService();
  
  List<PortraitModel> _userPortraits = [];
  List<PortraitModel> _allPortraits = [];
  bool _isLoading = false;
  String? _error;

  List<PortraitModel> get userPortraits => _userPortraits;
  List<PortraitModel> get allPortraits => _allPortraits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user's portraits
  Stream<List<PortraitModel>> getUserPortraits(String userId) {
    return _portraitService.getUserPortraits(userId);
  }

  // Get user's portraits in reverse order (newest first) for profile view
  Stream<List<PortraitModel>> getUserPortraitsReversed(String userId) {
    return _portraitService.getUserPortraitsReversed(userId);
  }

  // Get all portraits for community
  Stream<List<PortraitModel>> getAllPortraits() {
    return _portraitService.getAllPortraits();
  }

  // Add new portrait
  Future<bool> addPortrait({
    required String userId,
    required File imageFile,
    required String title,
    String? description,
    int? weekNumber,
    String? modelName,
    BuildContext? context,
  }) async {
    print('Starting portrait upload process');
    _setLoading(true);
    _clearError();
    
    try {
      print('Uploading image to Firebase Storage');
      // Upload image to Firebase Storage
      String imageUrl = await _portraitService.uploadPortraitImage(imageFile, userId);
      print('Image uploaded successfully');
      
      print('Adding portrait to Firestore');
      // Add portrait to Firestore
      await _portraitService.addPortrait(
        userId: userId,
        imageUrl: imageUrl,
        title: title,
        description: description,
        weekNumber: weekNumber,
        modelName: modelName,
      );
      print('Portrait added to Firestore');

      // Reload user data for up-to-date stats
      if (context != null) {
        print('Reloading user data');
        await Provider.of<AuthProvider>(context, listen: false).reloadUserData();
        print('User data reloaded');
      }
      _setLoading(false);
      print('Portrait upload process completed successfully');
      return true;
    } catch (e) {
      print('Error in addPortrait provider: $e');
      _setError('Failed to add portrait: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete portrait
  Future<bool> deletePortrait(String portraitId, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _portraitService.deletePortrait(portraitId, userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete portrait: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get next week number for user
  Future<int> getNextWeekNumber(String userId) async {
    try {
      return await _portraitService.getNextWeekNumber(userId);
    } catch (e) {
      _setError('Failed to get next week number: $e');
      return 1;
    }
  }

  // Get portrait by ID
  Future<PortraitModel?> getPortraitById(String portraitId) async {
    try {
      return await _portraitService.getPortraitById(portraitId);
    } catch (e) {
      _setError('Failed to get portrait: $e');
      return null;
    }
  }

  // Renumber portraits sequentially starting from week 1
  Future<bool> renumberPortraitsSequentially(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _portraitService.renumberPortraitsSequentially(userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to renumber portraits: $e');
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

  // Refresh portraits to notify listeners
  void refreshPortraits() {
    notifyListeners();
  }
} 
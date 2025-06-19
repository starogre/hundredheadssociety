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
    BuildContext? context,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Upload image to Firebase Storage
      String imageUrl = await _portraitService.uploadPortraitImage(imageFile, userId);
      
      // Add portrait to Firestore
      await _portraitService.addPortrait(
        userId: userId,
        imageUrl: imageUrl,
        title: title,
        description: description,
      );
      // Reload user data for up-to-date stats
      if (context != null) {
        await Provider.of<AuthProvider>(context, listen: false).reloadUserData();
      }
      _setLoading(false);
      return true;
    } catch (e) {
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
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../services/image_upload_service.dart';
import '../models/model_model.dart';

class ModelProvider extends ChangeNotifier {
  final ModelService _modelService = ModelService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  
  List<ModelModel> _models = [];
  bool _isLoading = false;
  String? _error;

  List<ModelModel> get models => _models;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all models
  Stream<List<ModelModel>> getModels() {
    return _modelService.getModels();
  }

  // Get active models only
  Stream<List<ModelModel>> getActiveModels() {
    return _modelService.getActiveModels();
  }

  // Add new model
  Future<bool> addModel({
    required String name,
    required DateTime date,
    String? notes,
    File? imageFile,
    bool isActive = true,
    BuildContext? context,
  }) async {
    print('Starting model upload process');
    _setLoading(true);
    _clearError();
    
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        print('Uploading model image');
        final fileName = '${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await _imageUploadService.uploadImage(imageFile, 'models', fileName);
        print('Model image uploaded: $imageUrl');
      }
      
      print('Adding model to Firestore');
      // Add model to Firestore
      await _modelService.addModel(
        name: name,
        date: date,
        notes: notes,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      print('Model added to Firestore');

      _setLoading(false);
      print('Model upload process completed successfully');
      return true;
    } catch (e) {
      print('Error in addModel provider: $e');
      _setError('Failed to add model: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update model
  Future<bool> updateModel({
    required String modelId,
    required String name,
    required DateTime date,
    String? notes,
    File? imageFile,
    bool isActive = true,
    BuildContext? context,
  }) async {
    print('Starting model update process');
    _setLoading(true);
    _clearError();
    
    try {
      String? imageUrl;
      
      // Upload new image if provided
      if (imageFile != null) {
        print('Uploading new model image');
        final fileName = '${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await _imageUploadService.uploadImage(imageFile, 'models', fileName);
        print('New model image uploaded: $imageUrl');
      }
      
      print('Updating model in Firestore');
      // Update model in Firestore
      await _modelService.updateModel(modelId, {
        'name': name,
        'date': date,
        'notes': notes,
        'imageUrl': imageUrl,
        'isActive': isActive,
      });
      print('Model updated in Firestore');

      _setLoading(false);
      print('Model update process completed successfully');
      return true;
    } catch (e) {
      print('Error in updateModel provider: $e');
      _setError('Failed to update model: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete model
  Future<bool> deleteModel(String modelId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _modelService.deleteModel(modelId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete model: $e');
      _setLoading(false);
      return false;
    }
  }

  // Import models from CSV
  Future<bool> importModelsFromCSV(String csvData) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _modelService.importModelsFromCSV(csvData);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to import models: $e');
      _setLoading(false);
      return false;
    }
  }

  // Export models to CSV
  Future<String> exportModelsToCSV() async {
    try {
      return await _modelService.exportModelsToCSV();
    } catch (e) {
      _setError('Failed to export models: $e');
      return '';
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
} 
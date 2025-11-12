import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/portrait_service.dart';

enum UploadStatus {
  idle,
  uploading,
  completed,
  error,
}

class PortraitUploadItem {
  final File imageFile;
  final String? description;
  final String? modelName;
  final int weekNumber;
  UploadStatus status;
  String? errorMessage;

  PortraitUploadItem({
    required this.imageFile,
    this.description,
    this.modelName,
    required this.weekNumber,
    this.status = UploadStatus.idle,
    this.errorMessage,
  });
}

class BulkUploadService extends ChangeNotifier {
  final PortraitService _portraitService = PortraitService();
  
  List<PortraitUploadItem> _uploadQueue = [];
  bool _isUploading = false;
  int _currentIndex = 0;
  String? _userId;

  // Getters
  bool get isUploading => _isUploading;
  int get totalCount => _uploadQueue.length;
  int get completedCount => _currentIndex;
  int get remainingCount => totalCount - completedCount;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0.0;
  List<PortraitUploadItem> get uploadQueue => List.unmodifiable(_uploadQueue);
  
  bool get hasItems => _uploadQueue.isNotEmpty;
  bool get isIdle => !_isUploading && _uploadQueue.isEmpty;

  // Start bulk upload
  void startBulkUpload({
    required String userId,
    required List<File> images,
    required List<String?> descriptions,
    required List<String?> modelNames,
    required List<int> weekNumbers,
  }) {
    if (_isUploading) {
      throw Exception('Upload already in progress');
    }

    // Create upload queue
    _uploadQueue = List.generate(
      images.length,
      (i) => PortraitUploadItem(
        imageFile: images[i],
        description: descriptions[i],
        modelName: modelNames[i],
        weekNumber: weekNumbers[i],
      ),
    );

    _userId = userId;
    _currentIndex = 0;
    _isUploading = true;
    notifyListeners();

    // Start uploading in background (fire and forget)
    _processUploadQueue();
  }

  // Process the upload queue
  Future<void> _processUploadQueue() async {
    while (_currentIndex < _uploadQueue.length && _isUploading) {
      final item = _uploadQueue[_currentIndex];
      
      try {
        // Mark as uploading
        item.status = UploadStatus.uploading;
        notifyListeners();

        // Step 1: Upload image to Firebase Storage
        final imageUrl = await _portraitService.uploadPortraitImage(
          item.imageFile,
          _userId!,
        );

        // Step 2: Add portrait document to Firestore
        await _portraitService.addPortrait(
          userId: _userId!,
          imageUrl: imageUrl,
          title: '', // Title deprecated
          description: item.description?.trim().isEmpty == true ? null : item.description?.trim(),
          weekNumber: item.weekNumber,
          modelName: item.modelName,
        );

        // Mark as completed
        item.status = UploadStatus.completed;
        _currentIndex++;
        notifyListeners();

        // Small delay between uploads to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Mark as error
        item.status = UploadStatus.error;
        item.errorMessage = e.toString();
        _currentIndex++;
        notifyListeners();

        // Continue to next item even if this one failed
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // Upload complete
    _isUploading = false;
    notifyListeners();

    // Auto-clear after a delay if all successful
    if (_uploadQueue.every((item) => item.status == UploadStatus.completed)) {
      await Future.delayed(const Duration(seconds: 3));
      clearQueue();
    }
  }

  // Cancel ongoing upload
  void cancelUpload() {
    _isUploading = false;
    notifyListeners();
  }

  // Clear the queue
  void clearQueue() {
    _uploadQueue.clear();
    _currentIndex = 0;
    _isUploading = false;
    _userId = null;
    notifyListeners();
  }

  // Retry failed uploads
  Future<void> retryFailed() async {
    if (_isUploading) return;

    // Reset failed items
    for (var item in _uploadQueue) {
      if (item.status == UploadStatus.error) {
        item.status = UploadStatus.idle;
        item.errorMessage = null;
      }
    }

    // Find first failed item
    _currentIndex = _uploadQueue.indexWhere((item) => item.status == UploadStatus.idle);
    if (_currentIndex == -1) {
      // No items to retry
      return;
    }

    _isUploading = true;
    notifyListeners();

    await _processUploadQueue();
  }

  // Get summary of upload results
  Map<String, int> getUploadSummary() {
    return {
      'total': totalCount,
      'completed': _uploadQueue.where((item) => item.status == UploadStatus.completed).length,
      'failed': _uploadQueue.where((item) => item.status == UploadStatus.error).length,
      'pending': _uploadQueue.where((item) => item.status == UploadStatus.idle).length,
    };
  }
}


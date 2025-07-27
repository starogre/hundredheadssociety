import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/model_model.dart';

class ModelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all models, ordered by date (newest first)
  Stream<List<ModelModel>> getModels() {
    return _firestore
        .collection('models')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get active models only
  Stream<List<ModelModel>> getActiveModels() {
    return _firestore
        .collection('models')
        .where('isActive', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get models with search and filter
  Stream<List<ModelModel>> getModelsWithFilter({
    String? searchQuery,
    String? sortBy = 'date', // 'date' or 'name'
    bool descending = true,
    bool? isActive,
  }) {
    Query query = _firestore.collection('models');

    // Apply filters
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    // Apply sorting - only sort by date if not filtering by isActive
    if (sortBy == 'name') {
      query = query.orderBy('name', descending: descending);
    } else if (isActive == null) {
      // Only sort by date if we're not filtering by isActive (to avoid composite index requirement)
      query = query.orderBy('date', descending: descending);
    }

    return query.snapshots().map((snapshot) {
      List<ModelModel> models = snapshot.docs
          .map((doc) => ModelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply search filter in memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        models = models.where((model) {
          return model.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 (model.notes != null && model.notes!.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();
      }

      // Apply sorting in memory if we couldn't do it in the query
      if (sortBy == 'date' && isActive != null) {
        models.sort((a, b) => descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
      }

      return models;
    });
  }

  // Get a single model by ID
  Future<ModelModel?> getModelById(String modelId) async {
    try {
      final doc = await _firestore.collection('models').doc(modelId).get();
      if (doc.exists) {
        return ModelModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting model by ID: $e');
      return null;
    }
  }

  // Add a new model
  Future<String> addModel({
    required String name,
    required DateTime date,
    String? imageUrl,
    String? notes,
    bool isActive = true,
  }) async {
    try {
      final now = DateTime.now();
      final modelData = {
        'name': name,
        'date': Timestamp.fromDate(date),
        'imageUrl': imageUrl,
        'notes': notes,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('models').add(modelData);
      print('Model added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding model: $e');
      rethrow;
    }
  }

  // Update an existing model
  Future<void> updateModel(String modelId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      // Convert date if provided
      if (data.containsKey('date') && data['date'] is DateTime) {
        data['date'] = Timestamp.fromDate(data['date']);
      }

      await _firestore.collection('models').doc(modelId).update(data);
      print('Model updated successfully: $modelId');
    } catch (e) {
      print('Error updating model: $e');
      rethrow;
    }
  }

  // Delete a model
  Future<void> deleteModel(String modelId) async {
    try {
      await _firestore.collection('models').doc(modelId).delete();
      print('Model deleted successfully: $modelId');
    } catch (e) {
      print('Error deleting model: $e');
      rethrow;
    }
  }

  // Bulk import models from CSV data
  Future<void> importModelsFromCSVData(List<Map<String, dynamic>> csvData) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final row in csvData) {
        if (row['name'] != null && row['name'].toString().isNotEmpty) {
          final modelRef = _firestore.collection('models').doc();
          final modelData = {
            'name': row['name'],
            'date': Timestamp.fromDate(row['date']),
            'imageUrl': null,
            'notes': row['notes'],
            'isActive': row['isActive'] ?? true,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          };
          batch.set(modelRef, modelData);
        }
      }

      await batch.commit();
      print('Bulk import completed: ${csvData.length} models imported');
    } catch (e) {
      print('Error importing models: $e');
      rethrow;
    }
  }

  // Get models for a specific date range
  Stream<List<ModelModel>> getModelsByDateRange(DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('models')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get recent models (last 30 days)
  Stream<List<ModelModel>> getRecentModels() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return getModelsByDateRange(thirtyDaysAgo, DateTime.now());
  }

  // Import models from CSV string
  Future<void> importModelsFromCSV(String csvData) async {
    try {
      // Parse CSV data and convert to list of maps
      final lines = csvData.trim().split('\n');
      final List<Map<String, dynamic>> parsedData = [];
      
      for (final line in lines.skip(1)) { // Skip header
        final parts = line.split(',');
        if (parts.length >= 2) {
          final dateStr = parts[0].trim();
          final name = parts[1].trim();
          
          if (name.isNotEmpty) {
            // Parse date (assuming format like "January 9" or "1/6/2025")
            DateTime date;
            try {
              if (dateStr.contains('/')) {
                // Format: "1/6/2025"
                final dateParts = dateStr.split('/');
                date = DateTime(
                  int.parse(dateParts[2]),
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                );
              } else {
                // Format: "January 9" (assume current year)
                final monthNames = [
                  'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'
                ];
                final monthDay = dateStr.split(' ');
                final month = monthNames.indexOf(monthDay[0]) + 1;
                final day = int.parse(monthDay[1]);
                date = DateTime(DateTime.now().year, month, day);
              }
            } catch (e) {
              print('Error parsing date: $dateStr, using current date');
              date = DateTime.now();
            }
            
            parsedData.add({
              'name': name,
              'date': date,
              'notes': parts.length > 2 ? parts[2].trim() : null,
              'isActive': true,
            });
          }
        }
      }
      
      await importModelsFromCSVData(parsedData);
    } catch (e) {
      print('Error importing CSV: $e');
      rethrow;
    }
  }

  // Export models to CSV string
  Future<String> exportModelsToCSV() async {
    try {
      final modelsSnapshot = await _firestore.collection('models').get();
      final models = modelsSnapshot.docs
          .map((doc) => ModelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      final csvLines = ['Date,Name,Notes,Active'];
      for (final model in models) {
        csvLines.add('${model.date.toString().split(' ')[0]},${model.name},${model.notes ?? ''},${model.isActive}');
      }
      
      return csvLines.join('\n');
    } catch (e) {
      print('Error exporting CSV: $e');
      rethrow;
    }
  }
} 
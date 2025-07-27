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


} 
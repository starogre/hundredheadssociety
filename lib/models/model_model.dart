import 'package:cloud_firestore/cloud_firestore.dart';

class ModelModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy; // User ID who created this model
  final List<String> weeklySessionIds; // Sessions this model was used in
  final int usageCount; // How many times this model has been used

  ModelModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
    this.weeklySessionIds = const [],
    this.usageCount = 0,
  });

  factory ModelModel.fromMap(Map<String, dynamic> map, String id) {
    return ModelModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      weeklySessionIds: List<String>.from(map['weeklySessionIds'] ?? []),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'weeklySessionIds': weeklySessionIds,
      'usageCount': usageCount,
    };
  }

  ModelModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    List<String>? weeklySessionIds,
    int? usageCount,
  }) {
    return ModelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      weeklySessionIds: weeklySessionIds ?? this.weeklySessionIds,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // Helper methods
  bool get isAvailable => isActive;
  
  // Check if model was used in a specific session
  bool wasUsedInSession(String sessionId) {
    return weeklySessionIds.contains(sessionId);
  }
  
  // Add session to usage history
  ModelModel addSessionUsage(String sessionId) {
    final updatedSessionIds = List<String>.from(weeklySessionIds);
    if (!updatedSessionIds.contains(sessionId)) {
      updatedSessionIds.add(sessionId);
    }
    
    return copyWith(
      weeklySessionIds: updatedSessionIds,
      usageCount: usageCount + 1,
    );
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';

class ModelModel {
  final String id;
  final String name;
  final DateTime date;
  final String? imageUrl;
  final String? notes; // For special events, cancelled sessions, etc.
  final bool isActive; // Whether this model session actually happened
  final DateTime createdAt;
  final DateTime updatedAt;

  ModelModel({
    required this.id,
    required this.name,
    required this.date,
    this.imageUrl,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModelModel.fromMap(Map<String, dynamic> map, String id) {
    return ModelModel(
      id: id,
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ModelModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? imageUrl,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get display name
  String get displayName {
    if (notes != null && notes!.isNotEmpty) {
      return '$name ($notes)';
    }
    return name;
  }

  // Helper method to get formatted date
  String get formattedDate {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Helper method to check if this is a valid model session
  bool get isValidSession {
    return isActive && name.isNotEmpty && name != 'OFF' && name != 'cancelled' && name != 'holiday!';
  }
} 